/// <summary>
/// Page Dialogo fecha (ID 50008).
/// </summary>
page 90308 "Date Dialog"
{

    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            Field("Inicio"; Inicio)
            {
                ApplicationArea = ALL;
                Caption = 'Date';
            }
        }
    }
    VAR
        Inicio: Date;

    PROCEDURE SetCampos(pInicio: Date);
    BEGIN
        // Setter method to initialize the Date and Time fields on the page
        Inicio := pInicio;
    END;

    PROCEDURE GetCampos(VAR pInicio: Date);
    BEGIN
        // Getter method for the entered datatime value
        pInicio := Inicio;
    END;

}