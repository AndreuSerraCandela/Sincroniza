/// <summary>
/// Page Sincroniza. Setup (ID 80092).
/// </summary>
page 90395 "Copy Company"
{
    Caption = 'Copy Company';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = true;
    PageType = List;
    SourceTable = AllObjWithCaption;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group("Company")
            {
                field("New Company"; "New Company")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        Companies: Record Company;
                    begin
                        If Not Companies.Get("New Company") then error(LableErrorCompanyDoesNotExist);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Companies: Record Company;
                    begin
                        If Page.RunModal(357, Companies) = Action::LookupOK Then
                            "New Company" := Companies.Name;
                        If Not Companies.Get("New Company") then error(LableErrorCompanyDoesNotExist);
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object ID';
                    Editable = false;
                    ToolTip = 'Specifies the ID of the table. ';
                }
                field("Object Caption"; Rec."Object Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Caption';
                    Editable = false;
                    ToolTip = 'Specifies the name of the table.';
                }
                field(LogModification; ChangeLogSetupTable."Log Modification")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Excluded Fields';
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;
                    ToolTip = 'Specifies that any modification of data is logged.';
                    trigger OnAssistEdit()
                    begin
                        AssistEdit;
                    end;

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        NewValue: Boolean;
                    begin
                        if ChangeLogSetupTable."Table No." <> Rec."Object ID" then begin
                            NewValue := ChangeLogSetupTable."Log Modification";
                            GetRec;
                            ChangeLogSetupTable."Log Modification" := NewValue;
                        end;

                        // if xChangeLogSetupTable.Get(ChangeLogSetupTable."Table No.") then begin
                        //     ChangeLogSetupTable.DelChangeLogFields(1);
                        // end;
                        ChangeLogSetupTableLogModifica;
                    end;

                }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Copy Company")
            {
                ApplicationArea = All;
                Image = CopyWorksheet;
                trigger OnAction()
                var
                    Sincroniza: Codeunit Synchronize;
                    Comapnies: Record Company;
                begin
                    ChangeLogSetupTable.SetRange("Log Modification", true);
                    if not ChangeLogSetupTable.FindFirst() Then Error('No table selected');
                    If ChangeLogSetupTable.FindFirst() Then
                        repeat
                            Sincroniza.CopiaEmpresa(ChangeLogSetupTable."Table No.", "New Company");
                        until ChangeLogSetupTable.Next() = 0;
                    Sincroniza.TerminaCopiado();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetRec;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        PageIsEditable := CurrPage.Editable();
    end;

    trigger OnOpenPage()
    begin

        Rec.FilterGroup(2);
        Rec.SetRange("Object Type", Rec."Object Type"::Table);
        Rec.SetRange("Object ID", 0, 2000000000);
        //MonitorSensitiveField.ExcludeMonitorTablesFromChangeLog(Rec);
        Rec.FilterGroup(0);
        SetSource();
        if Rec.FindFirst() Then;
    end;

    local procedure AssistEdit()
    var
        "Field": Record "Field";
        ChangeLogSetupFieldList: Page "Sincr Log Setup (Field) List";
    begin
        Field.FilterGroup(2);
        Field.SetRange(TableNo, Rec."Object ID");
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.FilterGroup(0);
        //with ChangeLogSetupTable do
        ChangeLogSetupFieldList.SelectColumn(
          false,
          false,
          false);
        ChangeLogSetupFieldList.SetTableView(Field);
        ChangeLogSetupFieldList.Run;
    end;

    var
        "New Company": Text[30];
        ChangeLogSetupTable: Record "Synchronize Setup (Table)" temporary;
        //MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
        Text002: Label 'You have changed the %1 field to no longer be %2. Do you want to remove the field selections?';
        LableErrorCompanyDoesNotExist: Label 'The company does not exist';
        PageIsEditable: Boolean;
        ChangeLogSettingsUpdated: Boolean;

    local procedure UpdateRec()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;

        //with ChangeLogSetupTable do
        // if ("Log Insertion" = "Log Insertion"::" ") and ("Log Modification" = "Log Modification"::" ") and
        //    ("Log Deletion" = "Log Deletion"::" ")
        // then begin
        //     if Delete then;
        // end else
        if not ChangeLogSetupTable.Modify then
            ChangeLogSetupTable.Insert;

        ChangeLogSettingsUpdated := true;
    end;

    local procedure GetRec()
    begin
        if not ChangeLogSetupTable.Get(Rec."Object ID") then begin
            ChangeLogSetupTable.Init();
            ChangeLogSetupTable."Table No." := Rec."Object ID";
        end;
    end;


    /// <summary>
    /// SetSource.
    /// </summary>
    procedure SetSource()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Rec.DeleteAll();

        AllObjWithCaption.SetCurrentKey("Object Type", "Object ID");
        AllObjWithCaption.SetRange("Object Type", Rec."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", 0, 2000000006);

        if AllObjWithCaption.Find('-') then
            repeat
                Rec := AllObjWithCaption;
                Rec.Insert;
            until AllObjWithCaption.Next() = 0;
    end;

    /// <summary>
    /// IsChangeLogSettingsUpdated.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsChangeLogSettingsUpdated(): Boolean
    begin
        exit(ChangeLogSettingsUpdated);
    end;

    local procedure ChangeLogSetupTableLogInsertio()
    begin
        UpdateRec;
    end;

    local procedure ChangeLogSetupTableLogModifica()
    begin
        UpdateRec;
    end;

    local procedure ChangeLogSetupTableLogDeletion()
    begin
        UpdateRec;
    end;


}
