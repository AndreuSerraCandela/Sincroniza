
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
        field(80101; "Subsidiarie"; Boolean)
        {
            Caption = 'Subsidiarie';
            DataClassification = ToBeClassified;
        }
        field(80102; "Master Company Name"; Text[30])
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
                    rInf.ChangeCompany(xRec."Master Company Name");
                    if Companies.Get(xRec."Master Company Name") then begin
                        SubsidiarieList := rInf.GetSubsidiarieList();
                        SubsidiarieList.Remove(CompanyName);
                        rInf.SetSubsidiarieList(SubsidiarieList);
                    end;
                end;
                if Companies.Get("Master Company Name") then begin
                    rInf.ChangeCompany("Master Company Name");
                    SubsidiarieList := rInf.GetSubsidiarieList();
                    SubsidiarieList.Add(CompanyName);
                    rInf.SetSubsidiarieList(SubsidiarieList);
                end;

            end;
        }
        //lista de empresas subordinadas
        field(80103; "Subsidiarie List"; Blob)
        {
            Caption = 'Subsidiarie List';
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
    begin
        CalcFields("Subsidiarie List");
        "Subsidiarie List".CreateInStream(InStream, TEXTENCODING::UTF8);
        SubsidiarieText := (TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Subsidiarie List")));
        SubsidiarieList := SubsidiarieText.Split(TypeHelper.LFSeparator());
        exit(SubsidiarieList);
    end;
}
