CLASS zcl_jev_http DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    INTERFACES zif_jev_http.

    CLASS-METHODS create_by_url
      IMPORTING iv_url         TYPE string
                iv_api_key     TYPE string OPTIONAL
                iv_timeout     TYPE i      DEFAULT 30
      RETURNING VALUE(ro_http) TYPE REF TO zcl_jev_http.

    CLASS-METHODS create_by_destination
      IMPORTING iv_destination TYPE string
                iv_timeout     TYPE i DEFAULT 30
      RETURNING VALUE(ro_http) TYPE REF TO zcl_jev_http.

    METHODS constructor
      IMPORTING iv_base_url    TYPE string OPTIONAL
                iv_api_key     TYPE string OPTIONAL
                iv_destination TYPE string OPTIONAL
                iv_timeout     TYPE i      DEFAULT 30.

  PRIVATE SECTION.
    DATA mv_base_url    TYPE string.
    DATA mv_api_key     TYPE string.
    DATA mv_destination TYPE c LENGTH 32.
    DATA mv_timeout     TYPE i.

    METHODS build_url
      IMPORTING iv_path       TYPE string
      RETURNING VALUE(rv_url) TYPE string.
ENDCLASS.


CLASS zcl_jev_http IMPLEMENTATION.
  METHOD create_by_url.
    CREATE OBJECT ro_http
      EXPORTING iv_base_url = iv_url
                iv_api_key  = iv_api_key
                iv_timeout  = iv_timeout.
  ENDMETHOD.

  METHOD create_by_destination.
    CREATE OBJECT ro_http
      EXPORTING iv_destination = iv_destination
                iv_timeout     = iv_timeout.
  ENDMETHOD.

  METHOD constructor.
    mv_base_url    = iv_base_url.
    mv_api_key     = iv_api_key.
    mv_destination = iv_destination.
    mv_timeout     = iv_timeout.
  ENDMETHOD.

  METHOD build_url.
    DATA lv_base TYPE string.
    DATA lv_path TYPE string.
    DATA lv_len  TYPE i.

    lv_base = mv_base_url.
    IF lv_base CP '*/'.
      lv_len = strlen( lv_base ) - 1.
      lv_base = substring( val = lv_base
                           off = 0
                           len = lv_len ).
    ENDIF.

    lv_path = iv_path.
    IF lv_path NP '/*'.
      CONCATENATE '/' lv_path INTO lv_path.
    ENDIF.

    IF lv_base CS lv_path.
      rv_url = lv_base.
    ELSE.
      CONCATENATE lv_base lv_path INTO rv_url.
    ENDIF.
  ENDMETHOD.

  METHOD zif_jev_http~post.
    DATA lo_http_client TYPE REF TO if_http_client.
    DATA lv_full_url    TYPE string.
    DATA lv_error       TYPE string.
    DATA lv_auth        TYPE string.
    DATA lv_err_msg     TYPE string.

    IF mv_destination IS NOT INITIAL.
      cl_http_client=>create_by_destination( EXPORTING destination = mv_destination
                                             IMPORTING client      = lo_http_client ).
      IF lo_http_client IS NOT BOUND.
        CONCATENATE 'Unable to create HTTP client for destination: ' mv_destination INTO lv_err_msg.
        zcx_jev_error=>raise( lv_err_msg ).
      ENDIF.
    ELSE.
      lv_full_url = build_url( iv_path ).
      cl_http_client=>create_by_url( EXPORTING url    = lv_full_url
                                     IMPORTING client = lo_http_client ).
      IF lo_http_client IS NOT BOUND.
        CONCATENATE 'Unable to create HTTP client for URL: ' lv_full_url INTO lv_err_msg.
        zcx_jev_error=>raise( lv_err_msg ).
      ENDIF.
    ENDIF.

    lo_http_client->request->set_method( 'POST' ).
    lo_http_client->request->set_content_type( 'application/json' ).

    IF mv_api_key IS NOT INITIAL.
      CONCATENATE 'Bearer ' mv_api_key INTO lv_auth.
      lo_http_client->request->set_header_field( name  = 'Authorization'
                                                 value = lv_auth ).
    ENDIF.

    lo_http_client->request->set_cdata( iv_payload ).

    lo_http_client->send( EXPORTING  timeout = mv_timeout
                          EXCEPTIONS OTHERS  = 1 ).
    IF sy-subrc <> 0.
      lo_http_client->get_last_error( IMPORTING message = lv_error ).
      lo_http_client->close( EXCEPTIONS OTHERS = 1 ).
      zcx_jev_error=>raise( lv_error ).
    ENDIF.

    lo_http_client->receive( EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      lo_http_client->get_last_error( IMPORTING message = lv_error ).
      lo_http_client->close( EXCEPTIONS OTHERS = 1 ).
      zcx_jev_error=>raise( lv_error ).
    ENDIF.

    rv_response = lo_http_client->response->get_cdata( ).
    lo_http_client->close( EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.
ENDCLASS.
