/// <summary>
/// Codeunit GlobalTrigger (ID 90302).
/// </summary>
codeunit 90302 Synchronize
{
    SingleInstance = true;

    var
        Tablas: Record "Synchronize Setup (Table)";
        Campos: Record "Synchronize Setup (Field)";

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
    begin
        //Companies.SetRange("Table No.", TableId);
        //Companies.SetRange("Company Name", Empresa());
        ErrorEmpresa := false;
        If Companies.FindFirst() then
            repeat
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
            until Companies.Next() = 0;
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
            rInf.Get();
            //if rInf."Empresa para maestros" = false then Error('Subsidiarie');
            If Company.FindFirst() then begin
                enuso := true;
                repeat

                    If Empresa <> Company.Name Then begin
                        RecRef2.Open(RecRef.Number, false, Company.Name);
                        if RecRef2.Get(RecRef.RecordId) Then begin
                            RecRef2.Delete();
                        end;
                        RecRef2 := RecRef.Duplicate();
                        RecRef2.ChangeCompany(Company.Name);
                        RecRef2.Insert();
                        RecRef2.Close();
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
            //if rInf."Empresa para maestros" = false then Error('Subsidiarie');
            If Company.FindFirst() then begin
                enuso := true;
                repeat
                    If Empresa <> Company.Name Then begin
                        RecRef2.Open(RecRef.Number, false, Company.Name);
                        RecRefTemp.Open(RecRef.Number, true, Company.Name);
                        if RecRef2.Get(RecRef.RecordId) Then begin
                            RecRefTemp := RecRef2.Duplicate();
                            RecRef2.Delete();
                            RecRef2 := RecRef.Duplicate();
                            RecRef2.ChangeCompany(Company.Name);
                            RecRef2.Insert();
                            Campos.SetRange("Table No.", RecRef.Number);
                            Campos.SetRange(Exclude, true);
                            if Campos.FindFirst() then begin
                                repeat
                                    RecRef2.Field(Campos."Field No.").Value := RecRefTemp.Field(Campos."Field No.").Value;
                                //RecRef2.Field(Campos."Field No.").Validate();

                                until Campos.Next() = 0;
                                RecRef2.Modify();
                            end;
                            RecRef2.Close();
                            RecRefTemp.Close();
                        end else begin
                            RecRef2 := RecRef.Duplicate();
                            RecRef2.ChangeCompany(Company.Name);
                            RecRef2.Insert();
                            RecRef2.Close();
                            RecRefTemp.Close();
                        end;
                    end;
                until Company.Next() = 0;
                enuso := false;
            end;
        end;
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
            If Company.FindFirst() then begin
                enuso := true;
                repeat
                    If Empresa <> Company.Name Then begin
                        RecRef2.Open(RecRef.Number, false, Company.Name);
                        if RecRef2.Get(RecRef.RecordId) Then begin
                            RecRef2.Delete();

                        end;
                        RecRef2.Close();
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

    var
        enuso: Boolean;
        Subsidiarie: Label 'This is not master company';
        Rename: Label 'Rename is not allowed';
        ErrorEmpresa: Boolean;
        CopiandoEmpresa: Boolean;
}