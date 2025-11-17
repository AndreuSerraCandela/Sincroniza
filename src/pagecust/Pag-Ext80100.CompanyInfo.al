
/// <summary>
/// PageExtension CompanyInf (ID 80100) extends Record Company Information.
/// </summary>
pageextension 90302 CompanyInf extends "Company Information"
{
    layout
    {
        addlast(content)
        {
            group(Synchronize)
            {
                Caption = 'Synchronize';
                field("Master Company"; Rec."Master Company")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
