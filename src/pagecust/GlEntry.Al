
// /// <summary>
// /// PageExtension Gl Entry Extension (ID 90308) extends Record General Ledger Entries.
// /// </summary>
// pageextension 90308 "Gl Entry Extension" extends "General Ledger Entries"
// {
//     actions
//     {
//         addafter(ChangeDimensions)
//         {
//             action("Arregla Dimensión")
//             {
//                 applicationarea = All;
//                 trigger OnAction()
//                 var
//                     CodeunitControlProcesses: Codeunit "ControldeProcesos";
//                     glentry: Record "G/L Entry";
//                 begin
//                     CurrPage.SetSelectionFilter(glentry);
//                     CodeunitControlProcesses.UpdDimension(GLEntry);
//                 end;
//             }
//         }
//     }
// }
