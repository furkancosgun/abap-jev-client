CLASS zcl_jev_result DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_noul,
        key  TYPE string,
        prob TYPE f,
      END OF ty_s_noul.
    TYPES ty_t_noul TYPE HASHED TABLE OF ty_s_noul WITH UNIQUE KEY key.

    TYPES:
      BEGIN OF ty_s_prob,
        label TYPE string,
        prob  TYPE f,
      END OF ty_s_prob.
    TYPES ty_t_prob TYPE STANDARD TABLE OF ty_s_prob WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_choice,
        key           TYPE string,
        choice        TYPE string,
        confidence    TYPE f,
        probabilities TYPE ty_t_prob,
      END OF ty_s_choice.
    TYPES ty_t_choice TYPE HASHED TABLE OF ty_s_choice WITH UNIQUE KEY key.

    TYPES:
      BEGIN OF ty_s_score,
        key        TYPE string,
        score      TYPE f,
        confidence TYPE f,
      END OF ty_s_score.
    TYPES ty_t_score TYPE HASHED TABLE OF ty_s_score WITH UNIQUE KEY key.

    TYPES:
      BEGIN OF ty_s_usage,
        input_tokens  TYPE i,
        output_tokens TYPE i,
      END OF ty_s_usage.

    METHODS constructor
      IMPORTING it_nouls      TYPE ty_t_noul
                it_choices    TYPE ty_t_choice
                it_scores     TYPE ty_t_score
                is_usage      TYPE ty_s_usage OPTIONAL
                iv_latency_ms TYPE f          OPTIONAL.

    METHODS get_noul
      IMPORTING iv_key         TYPE string
      RETURNING VALUE(rv_prob) TYPE f.

    METHODS is_noul_true
      IMPORTING iv_key         TYPE string
                iv_threshold   TYPE f DEFAULT '0.5'
      RETURNING VALUE(rv_bool) TYPE abap_bool.

    METHODS get_choice
      IMPORTING iv_key           TYPE string
      RETURNING VALUE(rv_choice) TYPE string.

    METHODS get_choice_confidence
      IMPORTING iv_key         TYPE string
      RETURNING VALUE(rv_conf) TYPE f.

    METHODS get_choice_probabilities
      IMPORTING iv_key          TYPE string
      RETURNING VALUE(rt_probs) TYPE ty_t_prob.

    METHODS get_score
      IMPORTING iv_key          TYPE string
      RETURNING VALUE(rv_score) TYPE f.

    METHODS get_score_confidence
      IMPORTING iv_key         TYPE string
      RETURNING VALUE(rv_conf) TYPE f.

    METHODS get_latency_ms
      RETURNING VALUE(rv_latency) TYPE f.

    METHODS get_input_tokens
      RETURNING VALUE(rv_tokens) TYPE i.

    METHODS get_output_tokens
      RETURNING VALUE(rv_tokens) TYPE i.

    METHODS get_total_tokens
      RETURNING VALUE(rv_tokens) TYPE i.

  PRIVATE SECTION.
    DATA mt_nouls      TYPE ty_t_noul.
    DATA mt_choices    TYPE ty_t_choice.
    DATA mt_scores     TYPE ty_t_score.
    DATA ms_usage      TYPE ty_s_usage.
    DATA mv_latency_ms TYPE f.
ENDCLASS.


CLASS zcl_jev_result IMPLEMENTATION.
  METHOD constructor.
    mt_nouls      = it_nouls.
    mt_choices    = it_choices.
    mt_scores     = it_scores.
    ms_usage      = is_usage.
    mv_latency_ms = iv_latency_ms.
  ENDMETHOD.

  METHOD get_noul.
    FIELD-SYMBOLS <fs_noul> TYPE ty_s_noul.

    READ TABLE mt_nouls WITH TABLE KEY key = iv_key ASSIGNING <fs_noul>.
    IF sy-subrc = 0.
      rv_prob = <fs_noul>-prob.
    ENDIF.
  ENDMETHOD.

  METHOD is_noul_true.
    DATA lv_prob TYPE f.

    lv_prob = get_noul( iv_key ).
    rv_bool = boolc( lv_prob >= iv_threshold ).
  ENDMETHOD.

  METHOD get_choice.
    FIELD-SYMBOLS <fs_choice> TYPE ty_s_choice.

    READ TABLE mt_choices WITH TABLE KEY key = iv_key ASSIGNING <fs_choice>.
    IF sy-subrc = 0.
      rv_choice = <fs_choice>-choice.
    ENDIF.
  ENDMETHOD.

  METHOD get_choice_confidence.
    FIELD-SYMBOLS <fs_choice> TYPE ty_s_choice.

    READ TABLE mt_choices WITH TABLE KEY key = iv_key ASSIGNING <fs_choice>.
    IF sy-subrc = 0.
      rv_conf = <fs_choice>-confidence.
    ENDIF.
  ENDMETHOD.

  METHOD get_choice_probabilities.
    FIELD-SYMBOLS <fs_choice> TYPE ty_s_choice.

    READ TABLE mt_choices WITH TABLE KEY key = iv_key ASSIGNING <fs_choice>.
    IF sy-subrc = 0.
      rt_probs = <fs_choice>-probabilities.
    ENDIF.
  ENDMETHOD.

  METHOD get_score.
    FIELD-SYMBOLS <fs_score> TYPE ty_s_score.

    READ TABLE mt_scores WITH TABLE KEY key = iv_key ASSIGNING <fs_score>.
    IF sy-subrc = 0.
      rv_score = <fs_score>-score.
    ENDIF.
  ENDMETHOD.

  METHOD get_score_confidence.
    FIELD-SYMBOLS <fs_score> TYPE ty_s_score.

    READ TABLE mt_scores WITH TABLE KEY key = iv_key ASSIGNING <fs_score>.
    IF sy-subrc = 0.
      rv_conf = <fs_score>-confidence.
    ENDIF.
  ENDMETHOD.

  METHOD get_latency_ms.
    rv_latency = mv_latency_ms.
  ENDMETHOD.

  METHOD get_input_tokens.
    rv_tokens = ms_usage-input_tokens.
  ENDMETHOD.

  METHOD get_output_tokens.
    rv_tokens = ms_usage-output_tokens.
  ENDMETHOD.

  METHOD get_total_tokens.
    rv_tokens = ms_usage-input_tokens + ms_usage-output_tokens.
  ENDMETHOD.
ENDCLASS.
