CLASS zcl_jev_q_score DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES ty_t_criteria TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_payload,
        type         TYPE string,
        instructions TYPE string,
        criteria     TYPE ty_t_criteria,
      END OF ty_s_payload.

    INTERFACES zif_jev_question.

    METHODS constructor
      IMPORTING iv_instructions TYPE string
                it_criteria     TYPE ty_t_criteria.

  PRIVATE SECTION.
    DATA mv_instructions TYPE string.
    DATA mt_criteria     TYPE ty_t_criteria.
ENDCLASS.


CLASS zcl_jev_q_score IMPLEMENTATION.
  METHOD constructor.
    mv_instructions = iv_instructions.
    mt_criteria     = it_criteria.
  ENDMETHOD.

  METHOD zif_jev_question~build.
    DATA lr_data TYPE REF TO ty_s_payload.

    CREATE DATA lr_data.
    lr_data->type         = 'score'.
    lr_data->instructions = mv_instructions.
    lr_data->criteria     = mt_criteria.
    rr_data = lr_data.
  ENDMETHOD.
ENDCLASS.
