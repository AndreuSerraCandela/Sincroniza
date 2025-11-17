pageextension 90305 Empresas extends 357
{
    actions
    {
        addbefore("Create New Company")
        {
            action("Copy Company")
            {
                Caption = 'Copy Company';
                Image = Copy;
                ApplicationArea = All;
                trigger OnAction()
                var

                begin
                    Page.RunModal(Page::"Copy Company");
                end;
            }
        }
        addbefore("Create New Company_Promoted")
        {
            actionref("Copy Companies"; "Copy Company")
            {


            }
        }
    }
}
