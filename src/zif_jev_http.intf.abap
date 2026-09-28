INTERFACE zif_jev_http PUBLIC.
  METHODS post
    IMPORTING iv_path            TYPE string
              iv_payload         TYPE string
    RETURNING VALUE(rv_response) TYPE string
    RAISING   zcx_jev_error.
ENDINTERFACE.
