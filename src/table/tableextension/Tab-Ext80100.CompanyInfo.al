
/// <summary>
/// TableExtension CompanyInfo (ID 80100) extends Record Company Information.
/// </summary>
tableextension 90324 CompanyInfo extends "Company Information"
{
    fields
    {
        field(80100; "Master Company"; Boolean)
        {

            Caption = 'Master Company';
            DataClassification = ToBeClassified;

        }
        field(80101; "Empresa para maestros"; Text[30])
        {
            Caption = 'Empresa';
            DataClassification = ToBeClassified;
            TableRelation = Company;
            ObsoleteState = Removed;
        }
        //Sincornizacion Bidireccional
        field(80102; "Sincornizacion Bidireccional"; Boolean)
        {
            Caption = 'Sincornizacion Bidireccional';
            DataClassification = ToBeClassified;
        }
        field(80103; "Subsidiarie"; Boolean)
        {
            Caption = 'Subsidiarie';
            DataClassification = ToBeClassified;
        }
        field(80104; "Master Company Name"; Text[30])
        {
            Caption = 'Master Company Name';
            DataClassification = ToBeClassified;
            TableRelation = Company.Name;
            trigger OnValidate()
            var
                Companies: Record Company;
                SubsidiarieList: List of [Text];
                rInf: Record "Company Information";
            begin

                if xRec."Master Company Name" <> "Master Company Name" then begin
                    If xRec."Master Company Name" <> '' then begin
                        rInf.ChangeCompany(xRec."Master Company Name");
                        if Companies.Get(xRec."Master Company Name") then begin
                            SubsidiarieList := rInf.GetSubsidiarieList();
                            SubsidiarieList.Remove(CompanyName);
                            rInf.SetSubsidiarieList(SubsidiarieList);
                            commit();
                        end;
                    end;
                end;
                If "Master Company Name" = CompanyName Then begin
                    SubsidiarieList := GetSubsidiarieList();
                    SubsidiarieList.Add(CompanyName);
                    SetSubsidiarieList(SubsidiarieList);
                    commit();
                end else
                    if Companies.Get("Master Company Name") then begin
                        rInf.ChangeCompany("Master Company Name");
                        SubsidiarieList := rInf.GetSubsidiarieList();
                        SubsidiarieList.Add(CompanyName);
                        rInf.SetSubsidiarieList(SubsidiarieList);
                        commit();
                    end;

            end;

            trigger OnLookup()
            var
                Companies: Record Company;
                CompanyList: Page Companies;
                CompanyTemp: Record Company temporary;
                Info: Record "Company Information";
            begin
                If Companies.FindFirst() then
                    repeat
                        Info.changecompany(Companies.Name);
                        Info.Get();
                        if Info."Master Company" then begin
                            CompanyTemp := Companies;
                            CompanyTemp.Insert();
                        end;

                    until Companies.Next() = 0;

                If Page.RunModal(Page::Companies, CompanyTemp) = Action::LookupOK then begin
                    Validate("Master Company Name", CompanyTemp.Name);
                end;
            end;
        }
        //lista de empresas subordinadas
        field(80105; "Subsidiarie List"; Blob)
        {
            Caption = 'Subsidiarie List';
            DataClassification = ToBeClassified;
        }
        field(80106; "Cambio en Cola"; Boolean)
        {
            Caption = 'Cambio en Cola';
            DataClassification = ToBeClassified;
        }
    }
    procedure SetSubsidiarieList(NewSubsidiarieList: List of [Text])
    var
        OutStream: OutStream;
        TypeHelper: Codeunit "Type Helper";
        NewSubsidiarie: Text;
    begin
        Clear("Subsidiarie List");
        "Subsidiarie List".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        foreach NewSubsidiarie in NewSubsidiarieList do begin
            OutStream.WriteText(NewSubsidiarie);
            OutStream.WriteText(TypeHelper.LFSeparator());
        end;
        Modify();
    end;

    procedure GetSubsidiarieList(): List of [Text]
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        SubsidiarieText: Text;
        SubsidiarieList: List of [Text];
        SubsidiarieList2: List of [Text];
        Company: Record Company;
        CommpanyTemp: Record Company temporary;
        Empresa: Text;
    begin
        CalcFields("Subsidiarie List");
        "Subsidiarie List".CreateInStream(InStream, TEXTENCODING::UTF8);
        SubsidiarieText := (TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Subsidiarie List")));
        SubsidiarieList := SubsidiarieText.Split(TypeHelper.LFSeparator());
        foreach Empresa in SubsidiarieList do begin
            If Company.Get(Empresa) then begin
                If not CommpanyTemp.Get(Empresa) then begin
                    CommpanyTemp := Company;
                    CommpanyTemp.Insert()
                end;
            end;
        end;
        If CommpanyTemp.FindFirst() then begin
            repeat
                SubsidiarieList2.Add(CommpanyTemp.Name);
            until CommpanyTemp.Next() = 0;
        end;
        exit(SubsidiarieList2);
    end;
}
