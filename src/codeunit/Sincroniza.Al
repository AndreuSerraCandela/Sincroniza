/// <summary>
/// Codeunit GlobalTrigger (ID 90302).
/// </summary>
codeunit 90302 Synchronize
{
    SingleInstance = true;

    var
        Tablas: Record "Synchronize Setup (Table)";
        Campos: Record "Synchronize Setup (Field)";
        CambioenSubsidiaria: Boolean;

    trigger OnRun()
    begin
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
        if enuso then exit;
        ErrorEmpresa := false;
        CambioenSubsidiaria := false;
        rInf.Get();
        If (rInf."Sincornizacion Bidireccional") and (rInf."Empresa para maestros" <> '') then begin
            CambioenSubsidiaria := true;
        end;
        //      If Companies.FindFirst() then
        //          repeat
        if GetExecutionContext() = ExecutionContext::Normal then begin
            //rInf.ChangeCompany();
            rInf.Get();
            Tablas.ChangeCompany(rInf."Empresa para maestros");
        end;
        If Tablas.get(TableId) then begin
            OnDatabaseDelete := true;
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
            OnDatabaseRename := true;
            Campos.ChangeCompany(rInf."Empresa para maestros");
            exit;
        end;
        //           until Companies.Next() = 0;
        OnDatabaseDelete := false;
        OnDatabaseInsert := false;
        OnDatabaseModify := false;
        OnDatabaseRename := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnDatabaseInsert(RecRef: RecordRef)
    var
        Company: Record Company;
        RecRef2: RecordRef;
        rInf: Record "Company Information";
        Companies: Record Company;

    begin
        // We don't want to allow anyone to disable change log management in normal execution context
        if GetExecutionContext() = ExecutionContext::Normal then begin
            if enuso Then exit;
            if CopiandoEmpresa then exit;
            if CambioenSubsidiaria then begin
                rInf.Get();
                Tablas.ChangeCompany(rInf."Empresa para maestros");
                if Tablas.get(RecRef.Number) then begin
                    enuso := true;
                    RecRef2.Open(RecRef.Number, false, rInf."Empresa para maestros");
                    if RecRef2.Get(RecRef.RecordId) Then begin
                        RecRef2 := RecRef.Duplicate();
                        RecRef2.ChangeCompany(rInf."Empresa para maestros");
                        RecRef2.Modify(false);
                        Commit();
                        RecRef2.Close();
                    end else begin
                        RecRef2 := RecRef.Duplicate();
                        RecRef2.ChangeCompany(rInf."Empresa para maestros");
                        RecRef2.Insert(false);
                        Commit();
                        RecRef2.Close();
                    end;

                end;
            end;
            //if rInf."Empresa para maestros" = false then Error('Subsidiarie');
            If Company.FindFirst() then begin
                enuso := true;
                repeat
                    rInf.ChangeCompany(Company.Name);
                    rInf.Get();
                    Tablas.ChangeCompany(rInf."Empresa para maestros");
                    if Tablas.get(RecRef.Number) then begin
                        If (Empresa = rInf."Empresa para maestros") and (Empresa <> Company.Name) Then begin
                            RecRef2.Open(RecRef.Number, false, Company.Name);
                            if RecRef2.Get(RecRef.RecordId) Then begin
                                RecRef2.Delete(false);
                                RecRef2 := RecRef.Duplicate();
                                RecRef2.ChangeCompany(Company.Name);
                                RecRef2.Insert(false);
                                Commit();
                                RecRef2.Close();
                            end else begin
                                RecRef2 := RecRef.Duplicate();
                                RecRef2.ChangeCompany(Company.Name);
                                RecRef2.Insert(false);
                                Commit();
                                RecRef2.Close();
                            end;
                        end;
                    end;

                until Company.Next() = 0;
                enuso := false;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure OnDatabaseModify(RecRef: RecordRef)
    var
        Company: Record Company;
        RecRef2: RecordRef;
        RecRefTemp: RecordRef;
        rInf: Record "Company Information";

    begin
        // We don't want to allow anyone to disable change log management in normal execution context
        if GetExecutionContext() = ExecutionContext::Normal then begin
            rInf.Get();
            if enuso Then exit;
            if CopiandoEmpresa then exit;
            if CambioenSubsidiaria then begin

                rInf.Get();
                Tablas.ChangeCompany(rInf."Empresa para maestros");
                if Tablas.get(RecRef.Number) then begin
                    enuso := true;
                    RecRef2.Open(RecRef.Number, false, rInf."Empresa para maestros");
                    if RecRef2.Get(RecRef.RecordId) Then begin
                        RecRefTemp.Open(RecRef.Number, true, rInf."Empresa para maestros");
                        RecRefTemp := RecRef2.Duplicate();
                        RecRef2.Delete(false);
                        RecRef2 := RecRef.Duplicate();
                        RecRef2.ChangeCompany(rInf."Empresa para maestros");
                        RecRef2.Insert(false);
                        Campos.SetRange("Table No.", RecRef.Number);
                        Campos.SetRange(Exclude, true);
                        if Campos.FindFirst() then begin
                            repeat
                                RecRef2.Field(Campos."Field No.").Value := RecRefTemp.Field(Campos."Field No.").Value;
                            //RecRef2.Field(Campos."Field No.").Validate();

                            until Campos.Next() = 0;
                            RecRef2.Modify(false);
                            Commit();
                        end;
                        RecRef2.Get(RecRef.RecordId);
                        RecRef2.Close();
                        RecRefTemp.Close();
                    end else begin
                        RecRef2 := RecRef.Duplicate();
                        RecRef2.ChangeCompany(rInf."Empresa para maestros");
                        RecRef2.Insert(false);
                        Commit();
                        RecRef2.Close();
                    end;

                end;
            end;
            //if rInf."Empresa para maestros" = false then Error('Subsidiarie');
            If Company.FindFirst() then begin
                enuso := true;
                repeat
                    rInf.ChangeCompany(Company.Name);
                    rInf.Get();
                    Tablas.ChangeCompany(rInf."Empresa para maestros");
                    if Tablas.get(RecRef.Number) then begin
                        If (Empresa = rInf."Empresa para maestros") and (Empresa <> Company.Name) Then begin
                            RecRef2.Open(RecRef.Number, false, Company.Name);
                            RecRefTemp.Open(RecRef.Number, true, Company.Name);
                            if RecRef2.Get(RecRef.RecordId) Then begin
                                RecRefTemp := RecRef2.Duplicate();
                                RecRef2.Delete(false);
                                RecRef2 := RecRef.Duplicate();
                                RecRef2.ChangeCompany(Company.Name);
                                RecRef2.Insert(false);
                                Campos.SetRange("Table No.", RecRef.Number);
                                Campos.SetRange(Exclude, true);
                                if Campos.FindFirst() then begin
                                    repeat
                                        RecRef2.Field(Campos."Field No.").Value := RecRefTemp.Field(Campos."Field No.").Value;
                                    //RecRef2.Field(Campos."Field No.").Validate();

                                    until Campos.Next() = 0;
                                    RecRef2.Modify(false);
                                    Commit();
                                end;
                                RecRef2.Close();
                                RecRefTemp.Close();
                            end else begin
                                RecRef2 := RecRef.Duplicate();
                                RecRef2.ChangeCompany(Company.Name);
                                RecRef2.Insert(false);
                                Commit();
                                RecRef2.Close();
                                RecRefTemp.Close();
                            end;
                        end;
                    end;
                until Company.Next() = 0;
                enuso := false;
            end;
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure OnDatabaseDelete(RecRef: RecordRef)
    var
        Company: Record Company;
        RecRef2: RecordRef;
        rInf: Record "Company Information";
    begin
        // We don't want to allow anyone to disable change log management in normal execution context
        if GetExecutionContext() = ExecutionContext::Normal then begin
            rInf.Get();
            if enuso Then exit;
            if CopiandoEmpresa then exit;
            if CambioenSubsidiaria then begin
                rInf.Get();
                Tablas.ChangeCompany(rInf."Empresa para maestros");
                if Tablas.get(RecRef.Number) then begin
                    enuso := true;
                    RecRef2.Open(RecRef.Number, false, rInf."Empresa para maestros");
                    if RecRef2.Get(RecRef.RecordId) Then begin
                        RecRef2.Delete(false);
                    end;
                    RecRef2.Close();
                end;
            end;
            If Company.FindFirst() then begin
                enuso := true;
                repeat
                    rInf.ChangeCompany(Company.Name);
                    rInf.Get();
                    Tablas.ChangeCompany(rInf."Empresa para maestros");
                    if Tablas.get(RecRef.Number) then begin
                        If (Empresa = rInf."Empresa para maestros") and (Empresa <> Company.Name) Then begin
                            RecRef2.Open(RecRef.Number, false, Company.Name);
                            if RecRef2.Get(RecRef.RecordId) Then begin
                                RecRef2.Delete(false);

                            end;
                            RecRef2.Close();
                        end;
                    end;
                until Company.Next() = 0;
                enuso := false;
            end;
        end;
    end;

    procedure TerminaCopiado()
    begin
        CopiandoEmpresa := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure OnDatabaseRename(RecRef: RecordRef; xRecRef: RecordRef)
    var

    begin
        // We don't want to allow anyone to disable change log management in normal execution context
        if GetExecutionContext() = ExecutionContext::Normal then begin
            Error(Rename);
        end;

    end;
    /// <summary>
    /// Empresa.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure Empresa(): Text
    begin
        exit(CompanyName);
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
    procedure CopiarStockActual(EmpresaDestino: Text[30])
    var
        Item: Record Item;
        ItemDestino: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Company: Record Company;
        StockActual: Decimal;
        LineNo: Integer;
        EmpresaOrigen: Text[30];
    begin
        // Validaciones
        If EmpresaDestino = '' Then
            Error('No se puede dejar la empresa destino en blanco');

        EmpresaOrigen := CompanyName;
        If EmpresaOrigen = EmpresaDestino Then
            Error('La empresa origen y la destino no pueden ser la misma');

        // Verificar que existe la empresa destino
        If Not Company.Get(EmpresaDestino) Then
            Error('La empresa destino %1 no existe', EmpresaDestino);

        // Obtener plantilla y lote de diario de artículos (usando la primera disponible)
        ItemJournalTemplate.ChangeCompany(EmpresaDestino);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        If Not ItemJournalTemplate.FindFirst() Then
            Error('No se encontró una plantilla de diario de artículos en la empresa destino');

        ItemJournalBatch.ChangeCompany(EmpresaDestino);
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        If Not ItemJournalBatch.FindFirst() Then
            Error('No se encontró un lote de diario de artículos en la empresa destino');

        // Recorrer productos no bloqueados de la empresa origen
        Item.SetRange(Blocked, false);
        If Item.FindSet() Then begin
            repeat
                // Calcular y obtener stock actual del producto
                Item.CalcFields(Inventory);
                StockActual := Item.Inventory;

                // Solo procesar si hay stock
                If StockActual > 0 Then begin
                    // Verificar que el producto existe en la empresa destino
                    ItemDestino.ChangeCompany(EmpresaDestino);
                    If ItemDestino.Get(Item."No.") Then begin
                        // Obtener siguiente número de línea
                        ItemJournalLine.ChangeCompany(EmpresaDestino);
                        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
                        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
                        If ItemJournalLine.FindLast() Then
                            LineNo := ItemJournalLine."Line No." + 10000
                        Else
                            LineNo := 10000;

                        // Crear línea de diario de entrada positiva
                        ItemJournalLine.Init();
                        ItemJournalLine."Journal Template Name" := ItemJournalTemplate.Name;
                        ItemJournalLine."Journal Batch Name" := ItemJournalBatch.Name;
                        ItemJournalLine."Line No." := LineNo;
                        ItemJournalLine."Posting Date" := Today;
                        ItemJournalLine."Document Date" := Today;
                        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt.";
                        ItemJournalLine.Validate("Item No.", Item."No.");
                        ItemJournalLine.Validate(Quantity, StockActual);
                        ItemJournalLine."Document No." := 'COPIA-STOCK-' + Format(Today, 0, '<Year4><Month,2><Day,2>');
                        ItemJournalLine.Description := 'Copia de stock desde ' + EmpresaOrigen + ' - ' + Format(Today);
                        ItemJournalLine.Insert(true);
                    end;
                end;
            until Item.Next() = 0;
        end;
    end;

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

    var
        enuso: Boolean;
        Subsidiarie: Label 'This is not master company';
        Rename: Label 'Rename is not allowed';
        ErrorEmpresa: Boolean;
        CopiandoEmpresa: Boolean;
}