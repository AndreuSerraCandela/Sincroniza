// /// <summary>
// /// PageExtension SalesQuotes (ID 9305) extends Record Sales Quotes.
// /// </summary>
// pageextension 90306 SalesQuotes extends "Sales Quotes"
// {
//     actions
//     {
//         addfirst(processing)
//         {
//             action("Copy Quotes from Company")
//             {
//                 Caption = 'Copiar Ofertas desde Empresa';
//                 Image = Copy;
//                 ApplicationArea = All;
//                 ToolTip = 'Borra todas las ofertas de venta actuales y las copia desde otra empresa (incluyendo líneas)';
//                 trigger OnAction()
//                 var
//                     Company: Record Company;
//                     Sincroniza: Codeunit Synchronize;
//                     ConfirmManagement: Codeunit "Confirm Management";
//                     EmpresaOrigen: Text[30];
//                 begin
//                     // Mostrar diálogo para seleccionar empresa origen
//                     If Page.RunModal(357, Company) = Action::LookupOK Then begin
//                         EmpresaOrigen := Company.Name;

//                         // Confirmar acción (es destructiva, así que pedir confirmación)
//                         If ConfirmManagement.GetResponseOrDefault(
//                             StrSubstNo('¿Está seguro? Esta acción borrará TODAS las ofertas de venta actuales y las reemplazará con las de la empresa %1. ¿Desea continuar?', EmpresaOrigen),
//                             false) Then begin

//                             // Llamar a la función de copiar ofertas
//                             Sincroniza.CopiarOfertasVenta(EmpresaOrigen);
//                         end;
//                     end;
//                 end;
//             }
//         }
//     }
// }

