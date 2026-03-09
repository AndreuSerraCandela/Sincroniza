
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
            ObsoleteState = Removed;
            ObsoleteReason = 'Use "Empresa para maestros" instead';
        }
        field(80101; "Empresa para maestros"; Text[30])
        {
            Caption = 'Empresa';
            DataClassification = ToBeClassified;
            TableRelation = Company;
        }
        //Sincornizacion Bidireccional
        field(80102; "Sincornizacion Bidireccional"; Boolean)
        {
            Caption = 'Sincornizacion Bidireccional';
            DataClassification = ToBeClassified;
        }
    }
}
