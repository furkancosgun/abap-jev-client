CLASS zcx_jev_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_message TYPE string   OPTIONAL
                previous  LIKE previous OPTIONAL
      PREFERRED PARAMETER iv_message.

    CLASS-METHODS raise
      IMPORTING iv_message TYPE string
      RAISING   zcx_jev_error.

    CLASS-METHODS raise_syst
      RAISING zcx_jev_error.

    METHODS get_text REDEFINITION.

  PRIVATE SECTION.
    DATA mv_message TYPE string.
ENDCLASS.


CLASS zcx_jev_error IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    mv_message = iv_message.
  ENDMETHOD.

  METHOD get_text.
    IF mv_message IS NOT INITIAL.
      result = mv_message.
    ELSE.
      result = super->get_text( ).
    ENDIF.
  ENDMETHOD.

  METHOD raise.
    DATA lx_error TYPE REF TO zcx_jev_error.

    CREATE OBJECT lx_error
      EXPORTING iv_message = iv_message.
    RAISE EXCEPTION lx_error.
  ENDMETHOD.

  METHOD raise_syst.
    DATA lv_message TYPE string.
    DATA lx_error   TYPE REF TO zcx_jev_error.

    MESSAGE ID sy-msgid
            TYPE sy-msgty
            NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            INTO lv_message.

    CREATE OBJECT lx_error
      EXPORTING iv_message = lv_message.
    RAISE EXCEPTION lx_error.
  ENDMETHOD.
ENDCLASS.
