CLASS zcl_jev_q_choice DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES ty_t_criteria TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_payload,
        type         TYPE string,
        instructions TYPE string,
        criteria     TYPE REF TO data,
      END OF ty_s_payload.

    INTERFACES zif_jev_question.

    METHODS constructor
      IMPORTING iv_instructions TYPE string
                it_criteria     TYPE ty_t_criteria.

  PRIVATE SECTION.
    DATA mv_instructions TYPE string.
    DATA mt_criteria     TYPE ty_t_criteria.
ENDCLASS.


CLASS zcl_jev_q_choice IMPLEMENTATION.
  METHOD constructor.
    mv_instructions = iv_instructions.
    mt_criteria     = it_criteria.
  ENDMETHOD.

  METHOD zif_jev_question~build.
    DATA lt_components  TYPE cl_abap_structdescr=>component_table.
    DATA ls_component   TYPE cl_abap_structdescr=>component.
    DATA lr_data        TYPE REF TO ty_s_payload.
    DATA lo_structdescr TYPE REF TO cl_abap_structdescr.
    DATA lr_criteria    TYPE REF TO data.
    FIELD-SYMBOLS <fs_criteria> TYPE string.

    LOOP AT mt_criteria ASSIGNING <fs_criteria>.
      CLEAR ls_component.
      ls_component-name = to_upper( <fs_criteria> ).
      ls_component-type = cl_abap_elemdescr=>get_string( ).
      APPEND ls_component TO lt_components.
    ENDLOOP.

    lo_structdescr = cl_abap_structdescr=>create( lt_components ).
    CREATE DATA lr_criteria TYPE HANDLE lo_structdescr.

    CREATE DATA lr_data.
    lr_data->type         = 'choice'.
    lr_data->instructions = mv_instructions.
    lr_data->criteria     = lr_criteria.
    rr_data = lr_data.
  ENDMETHOD.
ENDCLASS.
