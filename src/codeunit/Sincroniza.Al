/// <summary>
/// Codeunit GlobalTrigger (ID 90302).
/// </summary>
codeunit 90302 Synchronize
{
    SingleInstance = true;

    var
    // Tablas: Record "Synchronize Setup (Table)";
    // Campos: Record "Synchronize Setup (Field)";

    trigger OnRun()
    begin
    end;



    procedure TerminaCopiado()
    begin
        CopiandoEmpresa := false;
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