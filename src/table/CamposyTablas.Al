/// <summary>
/// Table Sincronization Setup (Field) (ID 80404).
/// </summary>
table 90344 "Synchronize Setup (Field)"
{
    Caption = 'Synchronize Setup (Field)';
    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = "Synchronize Setup (Table)";
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table No."));
        }
        field(3; "Field Caption"; Text[100])
        {
            CalcFormula = Lookup(Field."Field Caption" WHERE(TableNo = FIELD("Table No."),
                                                              "No." = FIELD("Field No.")));
            Caption = 'Field Caption';
            FieldClass = FlowField;
        }

        field(9; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table No.")));
            Caption = 'Table Caption';
            FieldClass = FlowField;
        }
        field(10; "Exclude"; Boolean)
        {

        }

    }

    keys
    {
        key(Key1; "Table No.", "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }


}
table 90343 "Synchronize Setup (Table)"
{
    Caption = 'Synchronize Setup (Table)';

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(2; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table No.")));
            Caption = 'Table Caption';
            FieldClass = FlowField;
        }
        // field(3; "Log Insertion"; Option)
        // {
        //     Caption = 'Conf modificación';
        //     OptionCaption = ' ,Some Fields,All Fields';
        //     OptionMembers = " ","Some Fields","All Fields";

        //     trigger OnValidate()
        //     var
        //         ConfirmManagement: Codeunit "Confirm Management";
        //     begin
        //         if (xRec."Log Insertion" = xRec."Log Insertion"::"Some Fields") and (xRec."Log Insertion" <> "Log Insertion") then
        //             if ConfirmManagement.GetResponseOrDefault(
        //                  StrSubstNo(
        //                    Text001, xRec.FieldCaption("Log Insertion"), xRec."Log Insertion"), true)
        //             then
        //                 DelChangeLogFields(0);
        //     end;
        // }
        field(4; "Log Modification"; Boolean)
        {
            Caption = 'Excluded Fields';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin

                DelChangeLogFields(1);
            end;
        }
        field(5; "Borrar"; Option)
        {
            Caption = 'Delete';
            OptionCaption = 'No,Yes';
            OptionMembers = No,Yes;


        }
        // field(6; "Monitor Sensitive Field"; Boolean)
        // {
        //     DataClassification = SystemMetadata;
        // }
    }

    keys
    {
        key(Key1; "Table No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'You have changed the %1 field to no longer be %2. Do you want to remove the field selections?';

    /// <summary>
    /// DelChangeLogFields.
    /// </summary>
    /// <param name="InsModDel">Integer.</param>
    procedure DelChangeLogFields(InsModDel: Integer)
    var
        ChangeLogSetupField: Record "Synchronize Setup (Field)";
    begin
        ChangeLogSetupField.SetRange("Table No.", "Table No.");
        ChangeLogSetupField.DeleteAll();
    end;
}
table 90345 "Synchronize Changes"
{
    Caption = 'Synchronize Changes';
    DataPerCompany = false;
    fields
    {
        field(1; "Company Origen"; Text[30])
        {
            Caption = 'Company Origen';
        }
        field(2; RecordIdDet; RecordId)
        {
            Caption = 'RecordId';
        }
        field(3; Operation; Option)
        {
            Caption = 'Operation';
            OptionMembers = Insert,Modify,Delete;
        }
        field(4; FechaHoraCambio; DateTime)
        {
            Caption = 'FechaHoraCambio';
        }



    }
    keys
    {
        key(Key1; "Company Origen", RecordIdDet, Operation)
        {
            Clustered = true;
        }
        key(Key2; FechaHoraCambio)
        {
        }
    }
}