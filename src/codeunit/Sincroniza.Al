/// <summary>
/// Codeunit GlobalTrigger (ID 90302).
/// </summary>
codeunit 90302 Synchronize
{
    SingleInstance = true;
    Permissions = tabledata "Company Information" = RIMD, tabledata Company = RIMD,
    tabledata "Synchronize Setup (Table)" = RIMD, tabledata "Synchronize Setup (Field)" = RIMD;

    var
        Tablas: Record "Synchronize Setup (Table)";
        Campos: Record "Synchronize Setup (Field)";
        CambioenSubsidiaria: Boolean;
        enuso: Boolean;
        CopiandoEmpresa: Boolean;
        ErrorEmpresa: Boolean;
        ErrorSubsidiarie: Label 'This is not master company';
        Rename: Label 'Rename is not allowed';
        EmpresaOrigen: Text[30];
        // En minusculas
        NoPermisoInsertarLbl: Label 'No tiene permisos para insertar en esta tabla';
        NoPermisoModificarLbl: Label 'No tiene permisos para modificar en esta tabla';
        NoPermisoBorrarLbl: Label 'No tiene permisos para borrar en esta tabla';

    trigger OnRun()
    var
        SynchronizeChanges: Record "Synchronize Changes";
    begin
        SynchronizeChanges.SetCurrentKey(FechaHoraCambio);
        if SynchronizeChanges.FindSet() then
            repeat
                case SynchronizeChanges.Operation of
                    SynchronizeChanges.Operation::Insert:
                        InsertSynchronizeChanges(SynchronizeChanges);
                    SynchronizeChanges.Operation::Modify:
                        ModifySynchronizeChanges(SynchronizeChanges);
                    SynchronizeChanges.Operation::Delete:
                        DeleteSynchronizeChanges(SynchronizeChanges);
                end;
            until SynchronizeChanges.Next() = 0;
        SynchronizeChanges.DeleteAll();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]

    /// <summary>
    /// GetDatabaseTableTriggerSetup.
    /// </summary>
    /// <param name="TableId">Integer.</param>
    /// <param name="OnDatabaseInsert">VAR Boolean.</param>
    /// <param name="OnDatabaseModify">VAR Boolean.</param>
    /// <param name="OnDatabaseDelete">VAR Boolean.</param>
    /// <param name="OnDatabaseRename">VAR Boolean.</param>
    procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var

        Companies: Record Company;
        rInf: Record "Company Information";

    begin
        //Companies.SetRange("Table No.", TableId);
        //Companies.SetRange("Company Name", Empresa());
        //error('prueba');
        if enuso then exit;
        ErrorEmpresa := false;
        CambioenSubsidiaria := false;
        rInf.Get();
        If (rInf."Sincornizacion Bidireccional") and (rInf.Subsidiarie) then begin
            CambioenSubsidiaria := true;
        end;

        if (not rInf."Subsidiarie") and (not rInf."Master Company") then exit;
        // Si la empresa es a la vez Master y Subsidiaria: usar su propia config (Tablas/Campos) para los triggers.
        if (rInf."Master Company") and (rInf.Subsidiarie) then rInf."Master Company Name" := CompanyName;
        If Companies.Get(rInf."Master Company Name") then begin

            if GetExecutionContext() = ExecutionContext::Normal then
                Tablas.ChangeCompany(Companies.Name);
            If Tablas.get(TableId) then begin
                OnDatabaseDelete := true;
                OnDatabaseInsert := true;
                OnDatabaseModify := true;
                OnDatabaseRename := true;
                Campos.ChangeCompany(Companies.Name);
                exit;
            end;
        end;
        OnDatabaseDelete := false;
        OnDatabaseInsert := false;
        OnDatabaseModify := false;
        OnDatabaseRename := false;

    end;

    local procedure DebeBloquearPorNoBidireccional(RecRef: RecordRef): Boolean
    var
        rInf: Record "Company Information";
        Companies: Record Company;
    begin
        rInf.ChangeCompany(CompanyName);
        if not rInf.FindFirst() then
            exit(false);
        if not rInf.Subsidiarie then
            exit(false);
        if rInf."Master Company" then
            exit(false);
        if rInf."Sincornizacion Bidireccional" then
            exit(false);
        if not Companies.Get(rInf."Master Company Name") then
            exit(false);
        Tablas.ChangeCompany(Companies.Name);
        exit(Tablas.get(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnDatabaseInsert(RecRef: RecordRef)
    var
        Company: Record Company;
        SynchronizeChanges: Record "Synchronize Changes";
        rInf: Record "Company Information";
        Sincroniza: Codeunit "Synchronize";
    begin
        if GetExecutionContext() = ExecutionContext::Normal then begin
            if DebeBloquearPorNoBidireccional(RecRef) then
                Error(NoPermisoInsertarLbl);
            rInf.Get();
            if (rInf.Subsidiarie) and (Not rInf."Master Company") then
                rInf.ChangeCompany(rInf."Master Company Name");
            if Not rInf.Subsidiarie then
                if not rInf."Master Company" then exit;
            if enuso Then exit;
            if CopiandoEmpresa then exit;
            If Not SynchronizeChanges.Get(CompanyName, RecRef.RecordId, SynchronizeChanges.Operation::Insert) then begin
                enuso := true;
                SynchronizeChanges.Init();
                SynchronizeChanges."Company Origen" := CompanyName;
                SynchronizeChanges.RecordIdDet := RecRef.RecordId;
                SynchronizeChanges.Operation := SynchronizeChanges.Operation::Insert;
                SynchronizeChanges.FechaHoraCambio := CurrentDateTime();
                if rInf."Cambio en Cola" then SynchronizeChanges.Insert();
            end;
            if not rInf."Cambio en Cola" then
                InsertSynchronizeChanges(RecRef, CompanyName);
            enuso := false;

        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseModify, '', false, false)]
    local procedure OnDatabaseModify(RecRef: RecordRef)
    var
        Company: Record Company;
        rInf: Record "Company Information";
        SubsidiarieList: List of [Text];
        Subsidiarie: Text;
        Maestra: Text;
        SynchronizeChanges: Record "Synchronize Changes";
        Sincroniza: Codeunit "Synchronize";
        FilldList: Record Field;

    begin
        if GetExecutionContext() = ExecutionContext::Normal then begin
            if DebeBloquearPorNoBidireccional(RecRef) then
                Error(NoPermisoModificarLbl);
            if enuso then exit;
            rInf.Get();
            if (rInf.Subsidiarie) and (Not rInf."Master Company") then
                rInf.ChangeCompany(rInf."Master Company Name");
            if Not rInf.Subsidiarie then
                if not rInf."Master Company" then exit;
            if enuso Then exit;
            if CopiandoEmpresa then exit;

            If Not SynchronizeChanges.Get(CompanyName, RecRef.RecordId, SynchronizeChanges.Operation::Modify) then begin
                enuso := true;
                SynchronizeChanges.Init();
                SynchronizeChanges."Company Origen" := CompanyName;
                SynchronizeChanges.RecordIdDet := RecRef.RecordId;
                SynchronizeChanges.Operation := SynchronizeChanges.Operation::Modify;
                SynchronizeChanges.FechaHoraCambio := CurrentDateTime();
                if rInf."Cambio en Cola" then SynchronizeChanges.Insert();
            end;
            if not rInf."Cambio en Cola" then
                ModifySynchronizeChanges(RecRef, CompanyName);
            enuso := false;







        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseDelete, '', false, false)]
    local procedure OnDatabaseDelete(RecRef: RecordRef)
    var
        Company: Record Company;
        rInf: Record "Company Information";
        SynchronizeChanges: Record "Synchronize Changes";
        Sincroniza: Codeunit "Synchronize";
    begin
        if GetExecutionContext() = ExecutionContext::Normal then begin
            if DebeBloquearPorNoBidireccional(RecRef) then
                Error(NoPermisoBorrarLbl);
            rInf.Get();
            if (rInf.Subsidiarie) and (Not rInf."Master Company") then
                rInf.ChangeCompany(rInf."Master Company Name");
            if Not rInf.Subsidiarie then
                if not rInf."Master Company" then exit;
            if enuso Then exit;
            if CopiandoEmpresa then exit;
            If Not SynchronizeChanges.Get(CompanyName, RecRef.RecordId, SynchronizeChanges.Operation::Delete) then begin
                enuso := true;
                SynchronizeChanges.Init();
                SynchronizeChanges."Company Origen" := CompanyName;
                SynchronizeChanges.RecordIdDet := RecRef.RecordId;
                SynchronizeChanges.Operation := SynchronizeChanges.Operation::Delete;
                SynchronizeChanges.FechaHoraCambio := CurrentDateTime();
                if rInf."Cambio en Cola" then SynchronizeChanges.Insert();
            end;
            if not rInf."Cambio en Cola" then
                DeleteSynchronizeChanges(RecRef, CompanyName);
            enuso := false;

        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'OnGetIsAPIEnabled', '', false, false)]
    local procedure OnGetIsAPIEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
        if enuso then begin
            Handled := true;
            IsAPIEnabled := false;
        end;
    end;

    procedure PasarRegistroaOtraEmpresa(RecRefOrigen: RecordRef; NewCompany: Text; MasterCompany: Text)
    var
        RecRefDestino: RecordRef;
        i: Integer;
        FldOrig: FieldRef;
        FldDest: FieldRef;
        TempBlob: Codeunit "Temp Blob";
        IsNewRecord: Boolean;

    begin
        RecRefDestino.Open(RecRefOrigen.Number, false, NewCompany);
        IsNewRecord := RecRefDestino.Get(RecRefOrigen.RecordId);
        Campos.ChangeCompany(MasterCompany);

        // ... Open, Get origen, Init destino ...
        for i := 1 to RecRefOrigen.FieldCount do begin

            FldOrig := RecRefOrigen.FieldIndex(i);
            if FldOrig.Class() in [FieldClass::FlowField, FieldClass::FlowFilter] then
                continue;
            if Not FldOrig.Active then
                continue;
            if Campos.Get(RecRefOrigen.Number, FldOrig.Number) then
                if Campos.Exclude then continue;
            FldDest := RecRefDestino.Field(FldOrig.Number);
            if FldOrig.Type() = FieldType::Blob then begin
                // Blob: usar Temp Blob en lugar de Value := Value
                TempBlob.FromFieldRef(FldOrig);
                TempBlob.ToFieldRef(FldDest);
            end else
                FldDest.Value := FldOrig.Value;
        end;
        if IsNewRecord then
            RecRefDestino.Modify(false)
        else
            RecRefDestino.Insert(false);
    end;



    procedure ModifySynchronizeChanges(VAR SynchronizeChanges: Record "Synchronize Changes")
    var
        RecRef: RecordRef;

    begin
        if GetExecutionContext() = ExecutionContext::Normal then begin
            RecRef.open(SynchronizeChanges.RecordIdDet.TableNo, false, SynchronizeChanges."Company Origen");
            RecRef.Get(SynchronizeChanges.RecordIdDet);
            modifySynchronizeChanges(RecRef, SynchronizeChanges."Company Origen");

        end;

    end;

    procedure InsertSynchronizeChanges(VAR SynchronizeChanges: Record "Synchronize Changes")
    var
        RecRef: RecordRef;

    begin
        if GetExecutionContext() = ExecutionContext::Normal then begin
            RecRef.open(SynchronizeChanges.RecordIdDet.TableNo, false, SynchronizeChanges."Company Origen");
            RecRef.Get(SynchronizeChanges.RecordIdDet);
            InsertSynchronizeChanges(RecRef, SynchronizeChanges."Company Origen");
        end;

    end;

    procedure DeleteSynchronizeChanges(VAR SynchronizeChanges: Record "Synchronize Changes")
    var
        RecRef: RecordRef;

    begin
        if GetExecutionContext() = ExecutionContext::Normal then begin
            RecRef.open(SynchronizeChanges.RecordIdDet.TableNo, false, SynchronizeChanges."Company Origen");
            RecRef.Get(SynchronizeChanges.RecordIdDet);
            DeleteSynchronizeChanges(RecRef, SynchronizeChanges."Company Origen");

        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Record Restriction Mgt.", 'OnAllowRecordUsageOnBeforeSetFilter', '', false, false)]
    local procedure OnAllowRecordUsageOnBeforeSetFilter(var RestrictedRecord: Record "Restricted Record"; RecordReference: RecordRef)
    begin
        if enuso then RecordReference.Init();
    end;

    local procedure OnAfterSetDocumentAttachmentFiltersForRecRef(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef)
    begin
        if enuso then begin
            DocumentAttachment.SetRange("Table ID", -1);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnDeleteApprovalEntriesOnAfterApprovalEntrySetFilters', '', false, false)]
    local procedure OnDeleteApprovalEntriesOnAfterApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry")
    begin
        if enuso then ApprovalEntry.SetRange("Table ID", -1);
    end;

    [EventSubscriber(ObjectType::Table, DATABASE::Customer, 'OnBeforeIsContactUpdateNeeded', '', false, false)]
    local procedure OnBeforeIsContactUpdateNeeded(Customer: Record Customer; xCustomer: Record Customer; var UpdateNeeded: Boolean; ForceUpdateContact: Boolean)
    begin
        UpdateNeeded := false;
    end;

    /// <summary>
    /// Indica si la empresa destino (Company) debe recibir el cambio.
    /// Devuelve true = sí enviar; false = no enviar (cuando es la master o la empresa origen).
    /// </summary>
    local procedure CompararEmpresa(Empresa: Text; Maestra: Text; Company: Text): Boolean
    begin
        if Company = Maestra then exit(false);
        if Company = Empresa then exit(false);
        exit(true);
    end;


    procedure TerminaCopiado()
    begin
        CopiandoEmpresa := false;
    end;



    internal procedure CopiaEmpresa(TableNo: Integer; NuevaEmpresa: Text[30])
    var
        RecRef2: RecordRef;
        //RecRefTemp: RecordRef;
        RecRef: RecordRef;
    begin
        CopiandoEmpresa := true;
        If NuevaEmpresa = '' Then Error('No se puede dejar la empresa em blanco');
        If CompanyName = NuevaEmpresa Then Error('La empresa origen y la destino no puede ser la misma. No tiene ningún sentido');
        RecRef.Open(TableNo, false, CompanyName);
        If RecRef.FindFirst() Then
            repeat
                RecRef2.Open(RecRef.Number, false, NuevaEmpresa);
                if RecRef2.Get(RecRef.RecordId) Then begin
                    RecRef2.Delete();
                    RecRef2 := RecRef.Duplicate();
                    RecRef2.ChangeCompany(NuevaEmpresa);
                    RecRef2.Insert();
                    RecRef2.Close();

                end else begin
                    RecRef2 := RecRef.Duplicate();
                    RecRef2.ChangeCompany(NuevaEmpresa);
                    RecRef2.Insert();
                    RecRef2.Close();

                end;

            until RecRef.Next() = 0;
    end;

    /// <summary>
    /// Copia el stock actual de productos no bloqueados como entrada positiva en otra empresa.
    /// </summary>
    /// <param name="EmpresaDestino">Nombre de la empresa destino donde se creará la entrada de stock.</param>
    // procedure CopiarStockActual(EmpresaDestino: Text[30])
    // var
    //     Item: Record Item;
    //     ItemDestino: Record Item;
    //     ItemJournalLine: Record "Item Journal Line";
    //     ItemJournalTemplate: Record "Item Journal Template";
    //     ItemJournalBatch: Record "Item Journal Batch";
    //     Company: Record Company;
    //     StockActual: Decimal;
    //     LineNo: Integer;
    //     EmpresaOrigen: Text[30];
    // begin
    //     // Validaciones
    //     If EmpresaDestino = '' Then
    //         Error('No se puede dejar la empresa destino en blanco');

    //     EmpresaOrigen := CompanyName;
    //     If EmpresaOrigen = EmpresaDestino Then
    //         Error('La empresa origen y la destino no pueden ser la misma');

    //     // Verificar que existe la empresa destino
    //     If Not Company.Get(EmpresaDestino) Then
    //         Error('La empresa destino %1 no existe', EmpresaDestino);

    //     // Obtener plantilla y lote de diario de artículos (usando la primera disponible)
    //     ItemJournalTemplate.ChangeCompany(EmpresaDestino);
    //     ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
    //     ItemJournalTemplate.SetRange(Recurring, false);
    //     If Not ItemJournalTemplate.FindFirst() Then
    //         Error('No se encontró una plantilla de diario de artículos en la empresa destino');

    //     ItemJournalBatch.ChangeCompany(EmpresaDestino);
    //     ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
    //     If Not ItemJournalBatch.FindFirst() Then
    //         Error('No se encontró un lote de diario de artículos en la empresa destino');

    //     // Recorrer productos no bloqueados de la empresa origen
    //     Item.SetRange(Blocked, false);
    //     If Item.FindSet() Then begin
    //         repeat
    //             // Calcular y obtener stock actual del producto
    //             Item.CalcFields(Inventory);
    //             StockActual := Item.Inventory;

    //             // Solo procesar si hay stock
    //             If StockActual > 0 Then begin
    //                 // Verificar que el producto existe en la empresa destino
    //                 ItemDestino.ChangeCompany(EmpresaDestino);
    //                 If ItemDestino.Get(Item."No.") Then begin
    //                     // Obtener siguiente número de línea
    //                     ItemJournalLine.ChangeCompany(EmpresaDestino);
    //                     ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
    //                     ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
    //                     If ItemJournalLine.FindLast() Then
    //                         LineNo := ItemJournalLine."Line No." + 10000
    //                     Else
    //                         LineNo := 10000;

    //                     // Crear línea de diario de entrada positiva
    //                     ItemJournalLine.Init();
    //                     ItemJournalLine."Journal Template Name" := ItemJournalTemplate.Name;
    //                     ItemJournalLine."Journal Batch Name" := ItemJournalBatch.Name;
    //                     ItemJournalLine."Line No." := LineNo;
    //                     ItemJournalLine."Posting Date" := Today;
    //                     ItemJournalLine."Document Date" := Today;
    //                     ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt.";
    //                     ItemJournalLine.Validate("Item No.", Item."No.");
    //                     ItemJournalLine.Validate(Quantity, StockActual);
    //                     ItemJournalLine."Document No." := 'COPIA-STOCK-' + Format(Today, 0, '<Year4><Month,2><Day,2>');
    //                     ItemJournalLine.Description := 'Copia de stock desde ' + EmpresaOrigen + ' - ' + Format(Today);
    //                     ItemJournalLine.Insert(true);
    //                 end;
    //             end;
    //         until Item.Next() = 0;
    //     end;
    // end;

    /// <summary>
    /// Borra todas las ofertas de venta actuales y las copia desde otra empresa (incluyendo líneas).
    /// </summary>
    /// <param name="EmpresaOrigen">Nombre de la empresa origen desde donde se copiarán las ofertas.</param>
    procedure CopiarOfertasVenta(EmpresaOrigen: Text[30])
    var
        SalesHeaderOrigen: Record "Sales Header";
        SalesHeaderDestino: Record "Sales Header";
        SalesLineOrigen: Record "Sales Line";
        SalesLineDestino: Record "Sales Line";
        Company: Record Company;
        EmpresaDestino: Text[30];
        ContadorOfertas: Integer;
    begin
        // Validaciones
        If EmpresaOrigen = '' Then
            Error('No se puede dejar la empresa origen en blanco');

        EmpresaDestino := CompanyName;
        If EmpresaDestino = EmpresaOrigen Then
            Error('La empresa origen y la destino no pueden ser la misma');

        // Verificar que existe la empresa origen
        If Not Company.Get(EmpresaOrigen) Then
            Error('La empresa origen %1 no existe', EmpresaOrigen);

        // Borrar todas las ofertas de venta existentes en la empresa destino
        // Primero borrar todas las líneas
        SalesLineDestino.SetRange("Document Type", SalesLineDestino."Document Type"::Quote);
        If SalesLineDestino.FindSet() Then
            SalesLineDestino.DeleteAll(false);

        // Luego borrar todos los encabezados
        SalesHeaderDestino.SetRange("Document Type", SalesHeaderDestino."Document Type"::Quote);
        If SalesHeaderDestino.FindSet() Then
            SalesHeaderDestino.DeleteAll(false);

        // Copiar ofertas de venta desde la empresa origen
        SalesHeaderOrigen.ChangeCompany(EmpresaOrigen);
        SalesHeaderOrigen.SetRange("Document Type", SalesHeaderOrigen."Document Type"::Quote);
        SalesHeaderOrigen.SetRange(Status, SalesHeaderOrigen.Status::Open);
        SalesHeaderOrigen.SetRange("Document Date", 20250101D, Today);

        If SalesHeaderOrigen.FindSet() Then begin
            repeat
                ContadorOfertas += 1;

                // Copiar encabezado
                SalesHeaderDestino.Init();
                SalesHeaderDestino.TransferFields(SalesHeaderOrigen);

                // Validar para generar número automáticamente si es necesario
                SalesHeaderDestino.Insert(false);

                // Copiar líneas
                SalesLineOrigen.ChangeCompany(EmpresaOrigen);
                SalesLineOrigen.SetRange("Document Type", SalesLineOrigen."Document Type"::Quote);

                SalesLineOrigen.SetRange("Document No.", SalesHeaderOrigen."No.");

                If SalesLineOrigen.FindSet() Then begin
                    repeat
                        SalesLineDestino.Init();
                        SalesLineDestino.TransferFields(SalesLineOrigen);
                        SalesLineDestino."Document Type" := SalesLineDestino."Document Type"::Quote;
                        SalesLineDestino.Insert();
                    until SalesLineOrigen.Next() = 0;
                end;

            until SalesHeaderOrigen.Next() = 0;
        end;

        Message('Se han copiado %1 ofertas de venta desde la empresa %2.', ContadorOfertas, EmpresaOrigen);
    end;

    procedure ModifySynchronizeChanges(RecRef: RecordRef; EmpresaOrigen: Text[30])
    var
        rInfCurrent: Record "Company Information";
        rInf: Record "Company Information";
        SubsidiarieList: List of [Text];
        Subsidiarie: Text;
        Maestra: Text;
        Company: Record Company;
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        enuso := true;
        rInfCurrent.ChangeCompany(EmpresaOrigen);
        if not rInfCurrent.Get() then begin
            enuso := false;
            exit;
        end;

        // Tablas y campos siempre se leen de la empresa que es master (la que define la configuración).
        // Si estoy en una master no tengo "Master Company Name" porque ya soy la master.

        // Caso 1: Soy Master → los cambios solo van hacia mis subsidiarias.
        if rInfCurrent."Master Company" then begin
            Maestra := EmpresaOrigen;
            SubsidiarieList := rInfCurrent.GetSubsidiarieList();
            foreach Subsidiarie in SubsidiarieList do begin
                if not Company.Get(Subsidiarie) then
                    continue;
                Tablas.ChangeCompany(Maestra);
                rInf.ChangeCompany(Subsidiarie);
                rInf.Get();
                if (rInf."Master Company Name" <> Maestra) then
                    continue;
                if not Tablas.get(RecRef.Number) then
                    continue;

                if CompararEmpresa(EmpresaOrigen, Maestra, Company.Name) then
                    PasarRegistroaOtraEmpresa(RecRef, Company.Name, Maestra);
            end;
        end;

        // Caso 2: Soy Subsidiaria → subir el cambio a mi master (si sincronización bidireccional).
        if rInfCurrent.Subsidiarie then
            if rInfCurrent."Sincornizacion Bidireccional" then begin
                Maestra := rInfCurrent."Master Company Name";
                Tablas.ChangeCompany(Maestra);
                if Tablas.get(RecRef.Number) then
                    PasarRegistroaOtraEmpresa(RecRef, Maestra, Maestra);
            end;
        // Caso 3: Soy Subsidiaria y bidireccional → repartir al resto de subsidiarias de mi master, excluyéndome.
        if rInfCurrent.Subsidiarie then
            if rInfCurrent."Sincornizacion Bidireccional" then begin
                Maestra := rInfCurrent."Master Company Name";
                rInf.ChangeCompany(Maestra);
                rInf.Get();
                SubsidiarieList := rInf.GetSubsidiarieList();
                foreach Subsidiarie in SubsidiarieList do begin
                    if not Company.Get(Subsidiarie) then
                        continue;
                    rInf.ChangeCompany(Company.Name);
                    rInf.Get();
                    if (rInf."Master Company Name" <> Maestra) then
                        continue;
                    if Subsidiarie <> EmpresaOrigen then
                        if CompararEmpresa(EmpresaOrigen, Maestra, Company.Name) then
                            PasarRegistroaOtraEmpresa(RecRef, Company.Name, Maestra);
                end;
            end;

        enuso := false;
    end;

    procedure InsertSynchronizeChanges(RecRef: RecordRef; EmpresaOrigen: Text[30])
    var
        rInfCurrent: Record "Company Information";
        rInf: Record "Company Information";
        SubsidiarieList: List of [Text];
        Subsidiarie: Text;
        Maestra: Text;
        Company: Record Company;
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        enuso := true;
        rInfCurrent.ChangeCompany(EmpresaOrigen);
        if not rInfCurrent.Get() then begin
            enuso := false;
            exit;
        end;

        // Caso 1: Soy Master → insertar en mis subsidiarias.
        if rInfCurrent."Master Company" then begin
            Maestra := EmpresaOrigen;
            SubsidiarieList := rInfCurrent.GetSubsidiarieList();
            foreach Subsidiarie in SubsidiarieList do begin
                if not Company.Get(Subsidiarie) then
                    continue;
                Tablas.ChangeCompany(Maestra);
                rInf.ChangeCompany(Subsidiarie);
                rInf.Get();
                if (rInf."Master Company Name" <> Maestra) then
                    continue;
                if not Tablas.get(RecRef.Number) then
                    continue;
                if CompararEmpresa(EmpresaOrigen, Maestra, Company.Name) then
                    PasarRegistroaOtraEmpresa(RecRef, Company.Name, Maestra);
            end;
        end;

        // Caso 2: Soy Subsidiaria → subir el insert a mi master (si sincronización bidireccional).
        if rInfCurrent.Subsidiarie then
            if rInfCurrent."Sincornizacion Bidireccional" then begin
                Maestra := rInfCurrent."Master Company Name";
                Tablas.ChangeCompany(Maestra);
                if Tablas.get(RecRef.Number) then
                    PasarRegistroaOtraEmpresa(RecRef, Maestra, Maestra);
            end;

        // Caso 3: Soy Subsidiaria y bidireccional → repartir al resto de subsidiarias de mi master, excluyéndome.
        if rInfCurrent.Subsidiarie then
            if rInfCurrent."Sincornizacion Bidireccional" then begin
                Maestra := rInfCurrent."Master Company Name";
                rInf.ChangeCompany(Maestra);
                rInf.Get();
                SubsidiarieList := rInf.GetSubsidiarieList();
                foreach Subsidiarie in SubsidiarieList do begin
                    if not Company.Get(Subsidiarie) then
                        continue;
                    if Subsidiarie = EmpresaOrigen then
                        continue;
                    rInf.ChangeCompany(Company.Name);
                    rInf.Get();
                    if rInf."Master Company Name" <> Maestra then
                        continue;
                    Tablas.ChangeCompany(Maestra);
                    if not Tablas.get(RecRef.Number) then
                        continue;
                    if CompararEmpresa(EmpresaOrigen, Maestra, Company.Name) then
                        PasarRegistroaOtraEmpresa(RecRef, Company.Name, Maestra);
                end;
            end;

        enuso := false;
    end;

    procedure DeleteSynchronizeChanges(RecRef: RecordRef; EmpresaOrigen: Text[30])
    var
        rInfCurrent: Record "Company Information";
        rInf: Record "Company Information";
        SubsidiarieList: List of [Text];
        Subsidiarie: Text;
        Maestra: Text;
        RecRef2: RecordRef;
        Company: Record Company;
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;
        if CopiandoEmpresa then
            exit;

        enuso := true;
        rInfCurrent.ChangeCompany(EmpresaOrigen);
        if not rInfCurrent.Get() then begin
            enuso := false;
            exit;
        end;

        // Caso 1: Soy Master → borrar en mis subsidiarias (si la tabla tiene Borrar = Yes).
        if rInfCurrent."Master Company" then begin
            Maestra := EmpresaOrigen;
            SubsidiarieList := rInfCurrent.GetSubsidiarieList();
            foreach Subsidiarie in SubsidiarieList do begin
                if not Company.Get(Subsidiarie) then
                    continue;
                Tablas.ChangeCompany(Maestra);
                rInf.ChangeCompany(Subsidiarie);
                rInf.Get();
                if (rInf."Master Company Name" <> Maestra) then
                    continue;
                if not Tablas.get(RecRef.Number) then
                    continue;
                if not (Tablas.Borrar = Tablas.Borrar::Yes) then
                    continue;
                if not CompararEmpresa(EmpresaOrigen, Maestra, Company.Name) then
                    continue;
                RecRef2.Open(RecRef.Number, false, Company.Name);
                if RecRef2.Get(RecRef.RecordId) then
                    RecRef2.Delete(false);
                RecRef2.Close();
            end;
        end;

        // Caso 2: Soy Subsidiaria → subir el borrado a mi master (si bidireccional y Tablas.Borrar = Yes).
        if rInfCurrent.Subsidiarie then
            if rInfCurrent."Sincornizacion Bidireccional" then begin
                Maestra := rInfCurrent."Master Company Name";
                Tablas.ChangeCompany(Maestra);
                if Tablas.get(RecRef.Number) then
                    if Tablas.Borrar = Tablas.Borrar::Yes then begin
                        RecRef2.Open(RecRef.Number, false, Maestra);
                        if RecRef2.Get(RecRef.RecordId) then
                            RecRef2.Delete(false);
                        RecRef2.Close();
                    end;
            end;

        // Caso 3: Soy Subsidiaria y bidireccional → repartir el borrado al resto de subsidiarias de mi master, excluyéndome.
        if rInfCurrent.Subsidiarie then
            if rInfCurrent."Sincornizacion Bidireccional" then begin
                Maestra := rInfCurrent."Master Company Name";
                rInf.ChangeCompany(Maestra);
                rInf.Get();
                SubsidiarieList := rInf.GetSubsidiarieList();
                foreach Subsidiarie in SubsidiarieList do begin
                    if not Company.Get(Subsidiarie) then
                        continue;
                    if Subsidiarie = EmpresaOrigen then
                        continue;
                    rInf.ChangeCompany(Company.Name);
                    rInf.Get();
                    if rInf."Master Company Name" <> Maestra then
                        continue;
                    Tablas.ChangeCompany(Maestra);
                    if not Tablas.get(RecRef.Number) then
                        continue;
                    if Tablas.Borrar <> Tablas.Borrar::Yes then
                        continue;
                    if not CompararEmpresa(EmpresaOrigen, Maestra, Company.Name) then
                        continue;
                    RecRef2.Open(RecRef.Number, false, Company.Name);
                    if RecRef2.Get(RecRef.RecordId) then
                        RecRef2.Delete(false);
                    RecRef2.Close();
                end;
            end;

        enuso := false;
    end;





}