// /// <summary>
// /// PageExtension DimensionValuesExt (ID 90306) extends Record Dimension Values.
// /// </summary>
// pageextension 90306 DimensionValuesExt extends "Dimension Values"
// {
//     layout
//     {
//         addafter(Blocked)
//         {
//             field("Dimension Value ID"; Rec."Dimension Value ID")
//             {
//                 ApplicationArea = All;
//                 Visible = true;
//             }
//             field("Modificar Dimension"; NewDeminsionCode)
//             {
//                 ApplicationArea = All;
//                 Visible = true;

//                 trigger OnValidate()
//                 var
//                     OldDim: Record "Dimension Value";
//                 begin
//                     if (NewDeminsionCode <> 0) then begin
//                         OldDim := Rec;
//                         Rec.Delete;
//                         Rec.Init;
//                         Rec."Dimension Code" := OldDim."Dimension Code";
//                         Rec.Code := OldDim.Code;
//                         Rec.Name := OldDim.Name;
//                         rec."Dimension Id" := OldDim."Dimension Id";
//                         Rec."Dimension Value Type" := OldDim."Dimension Value Type";
//                         Rec."Global Dimension No." := OldDim."Global Dimension No.";
//                         Rec.Blocked := OldDim.Blocked;
//                         rec."Consolidation Code" := OldDim."Consolidation Code";
//                         Rec.Indentation := OldDim.Indentation;
//                         rec."Last Modified Date Time" := OldDim."Last Modified Date Time";
//                         Rec."Map-to IC Dimension Code" := OldDim."Map-to IC Dimension Code";
//                         Rec."Map-to IC Dimension Value Code" := OldDim."Map-to IC Dimension Value Code";


//                         Rec.Insert(true);
//                     end;
//                 end;

//             }
//         }

//     }
//     var
//         NewDeminsionCode: Integer;

//     trigger OnAfterGetRecord()
//     begin
//         NewDeminsionCode := Rec."Dimension Value ID";
//     end;

// }
