
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
                field("Sincornizacion Bidireccional"; Rec."Sincornizacion Bidireccional")
                {
                    ApplicationArea = All;
                }
                field("Subsidiarie"; Rec."Subsidiarie")
                {
                    ApplicationArea = All;
                }
                field("Master Company Name"; Rec."Master Company Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        addafter("Payment Days")
        {
            action("Synchronize Setup")
            {
                Caption = 'Synchronize Setup';
                Image = Setup;
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Page.RunModal(Page::"Synchronize Setup");
                end;
            }
            // action("Copy Stock to Company")
            // {
            //     Caption = 'Copiar Stock a Empresa';
            //     Image = CopyItem;
            //     ApplicationArea = All;
            //     ToolTip = 'Copia el stock actual de productos no bloqueados como entrada positiva en otra empresa';
            //     trigger OnAction()
            //     var
            //         Company: Record Company;
            //         Sincroniza: Codeunit Synchronize;
            //         ConfirmManagement: Codeunit "Confirm Management";
            //         EmpresaDestino: Text[30];
            //     begin
            //         // Mostrar diálogo para seleccionar empresa destino
            //         If Page.RunModal(357, Company) = Action::LookupOK Then begin
            //             EmpresaDestino := Company.Name;

            //             // Confirmar acción
            //             If ConfirmManagement.GetResponseOrDefault(
            //                 StrSubstNo('¿Desea copiar el stock actual de productos no bloqueados a la empresa %1?', EmpresaDestino),
            //                 false) Then begin

            //                 // Llamar a la función de copiar stock
            //                 Sincroniza.CopiarStockActual(EmpresaDestino);
            //                 Message('Stock copiado correctamente a la empresa %1. Revise el diario de artículos para registrar las entradas.', EmpresaDestino);
            //             end;
            //         end;
            //     end;
            // }
        }
    }
}
