CLASS zcl_jev_q_noul DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_payload,
        type         TYPE string,
        instructions TYPE string,
      END OF ty_s_payload.

    INTERFACES zif_jev_question.

    METHODS constructor
      IMPORTING iv_instructions TYPE string.

  PRIVATE SECTION.
    DATA mv_instructions TYPE string.
ENDCLASS.


CLASS zcl_jev_q_noul IMPLEMENTATION.
  METHOD constructor.
    mv_instructions = iv_instructions.
  ENDMETHOD.

  METHOD zif_jev_question~build.
    DATA lr_data TYPE REF TO ty_s_payload.

    CREATE DATA lr_data.
    lr_data->type         = 'noul'.
    lr_data->instructions = mv_instructions.
    rr_data = lr_data.
  ENDMETHOD.
ENDCLASS.
