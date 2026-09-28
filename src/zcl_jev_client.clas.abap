CLASS zcl_jev_client DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_question,
        name     TYPE string,
        question TYPE REF TO zif_jev_question,
      END OF ty_s_question.
    TYPES ty_t_question TYPE HASHED TABLE OF ty_s_question WITH UNIQUE KEY name.

    TYPES:
      BEGIN OF ty_s_request_payload,
        model     TYPE string,
        state     TYPE string,
        questions TYPE REF TO data,
      END OF ty_s_request_payload.

    CLASS-METHODS create_by_url
      IMPORTING iv_url           TYPE string
                iv_api_key       TYPE string OPTIONAL
                iv_model         TYPE string DEFAULT 'kev-latest'
                iv_timeout       TYPE i      DEFAULT 30
      RETURNING VALUE(ro_client) TYPE REF TO zcl_jev_client.

    CLASS-METHODS create_by_destination
      IMPORTING iv_destination   TYPE string
                iv_model         TYPE string DEFAULT 'kev-latest'
                iv_timeout       TYPE i      DEFAULT 30
      RETURNING VALUE(ro_client) TYPE REF TO zcl_jev_client.

    CLASS-METHODS create
      IMPORTING io_http          TYPE REF TO zif_jev_http
                iv_model         TYPE string DEFAULT 'kev-latest'
      RETURNING VALUE(ro_client) TYPE REF TO zcl_jev_client.

    METHODS constructor
      IMPORTING io_http  TYPE REF TO zif_jev_http
                iv_model TYPE string DEFAULT 'kev-latest'.

    METHODS set_model
      IMPORTING iv_model         TYPE string
      RETURNING VALUE(ro_client) TYPE REF TO zcl_jev_client.

    METHODS add_noul
      IMPORTING iv_name          TYPE string
                iv_instructions  TYPE string
      RETURNING VALUE(ro_client) TYPE REF TO zcl_jev_client.

    METHODS add_choice
      IMPORTING iv_name          TYPE string
                iv_instructions  TYPE string
                it_criteria      TYPE zcl_jev_q_choice=>ty_t_criteria
      RETURNING VALUE(ro_client) TYPE REF TO zcl_jev_client.

    METHODS add_score
      IMPORTING iv_name          TYPE string
                iv_instructions  TYPE string
                it_criteria      TYPE zcl_jev_q_score=>ty_t_criteria
      RETURNING VALUE(ro_client) TYPE REF TO zcl_jev_client.

    METHODS add_question
      IMPORTING iv_name          TYPE string
                io_question      TYPE REF TO zif_jev_question
      RETURNING VALUE(ro_client) TYPE REF TO zcl_jev_client.

    METHODS clear_questions
      RETURNING VALUE(ro_client) TYPE REF TO zcl_jev_client.

    METHODS evaluate
      IMPORTING iv_state         TYPE string
      RETURNING VALUE(ro_result) TYPE REF TO zcl_jev_result
      RAISING   zcx_jev_error.

    METHODS evaluate_permuted
      IMPORTING iv_state         TYPE string
      RETURNING VALUE(ro_result) TYPE REF TO zcl_jev_result
      RAISING   zcx_jev_error.

    METHODS evaluate_separated
      IMPORTING iv_state         TYPE string
      RETURNING VALUE(ro_result) TYPE REF TO zcl_jev_result
      RAISING   zcx_jev_error.

    METHODS is_true
      IMPORTING iv_state       TYPE string
                iv_instruction TYPE string
                iv_threshold   TYPE f DEFAULT '0.5'
      RETURNING VALUE(rv_bool) TYPE abap_bool
      RAISING   zcx_jev_error.

    METHODS classify
      IMPORTING iv_state         TYPE string
                iv_instruction   TYPE string
                it_options       TYPE zcl_jev_q_choice=>ty_t_criteria
      RETURNING VALUE(rv_choice) TYPE string
      RAISING   zcx_jev_error.

    METHODS score
      IMPORTING iv_state        TYPE string
                iv_instruction  TYPE string
                it_levels       TYPE zcl_jev_q_score=>ty_t_criteria
      RETURNING VALUE(rv_score) TYPE f
      RAISING   zcx_jev_error.

  PRIVATE SECTION.
    DATA mv_model     TYPE string.
    DATA mo_http      TYPE REF TO zif_jev_http.
    DATA mt_questions TYPE ty_t_question.

    METHODS execute
      IMPORTING iv_path          TYPE string DEFAULT '/v1/systemone'
                iv_state         TYPE string
                it_questions     TYPE ty_t_question
      RETURNING VALUE(ro_result) TYPE REF TO zcl_jev_result
      RAISING   zcx_jev_error.

    METHODS build_payload
      IMPORTING iv_state          TYPE string
                it_questions      TYPE ty_t_question
      RETURNING VALUE(rv_payload) TYPE string.

    METHODS parse_response
      IMPORTING iv_json          TYPE string
      RETURNING VALUE(ro_result) TYPE REF TO zcl_jev_result.

    METHODS parse_usage
      IMPORTING ir_usage        TYPE REF TO data
      RETURNING VALUE(rs_usage) TYPE zcl_jev_result=>ty_s_usage.

    METHODS parse_choice_probabilities
      IMPORTING ir_prob         TYPE REF TO data
      RETURNING VALUE(rt_probs) TYPE zcl_jev_result=>ty_t_prob.

    METHODS parse_answer_item
      IMPORTING iv_name    TYPE string
                ir_item    TYPE REF TO data
      CHANGING  ct_nouls   TYPE zcl_jev_result=>ty_t_noul
                ct_choices TYPE zcl_jev_result=>ty_t_choice
                ct_scores  TYPE zcl_jev_result=>ty_t_score.
ENDCLASS.


CLASS zcl_jev_client IMPLEMENTATION.
  METHOD create_by_url.
    DATA lo_http TYPE REF TO zcl_jev_http.

    lo_http = zcl_jev_http=>create_by_url( iv_url     = iv_url
                                           iv_api_key = iv_api_key
                                           iv_timeout = iv_timeout ).
    CREATE OBJECT ro_client
      EXPORTING io_http  = lo_http
                iv_model = iv_model.
  ENDMETHOD.

  METHOD create_by_destination.
    DATA lo_http TYPE REF TO zcl_jev_http.

    lo_http = zcl_jev_http=>create_by_destination( iv_destination = iv_destination
                                                   iv_timeout     = iv_timeout ).
    CREATE OBJECT ro_client
      EXPORTING io_http  = lo_http
                iv_model = iv_model.
  ENDMETHOD.

  METHOD create.
    CREATE OBJECT ro_client
      EXPORTING io_http  = io_http
                iv_model = iv_model.
  ENDMETHOD.

  METHOD constructor.
    mo_http  = io_http.
    mv_model = iv_model.
  ENDMETHOD.

  METHOD set_model.
    mv_model = iv_model.
    ro_client = me.
  ENDMETHOD.

  METHOD add_noul.
    DATA lo_q TYPE REF TO zcl_jev_q_noul.

    CREATE OBJECT lo_q
      EXPORTING iv_instructions = iv_instructions.

    add_question( iv_name     = iv_name
                  io_question = lo_q ).
    ro_client = me.
  ENDMETHOD.

  METHOD add_choice.
    DATA lo_q TYPE REF TO zcl_jev_q_choice.

    CREATE OBJECT lo_q
      EXPORTING iv_instructions = iv_instructions
                it_criteria     = it_criteria.

    add_question( iv_name     = iv_name
                  io_question = lo_q ).
    ro_client = me.
  ENDMETHOD.

  METHOD add_score.
    DATA lo_q TYPE REF TO zcl_jev_q_score.

    CREATE OBJECT lo_q
      EXPORTING iv_instructions = iv_instructions
                it_criteria     = it_criteria.

    add_question( iv_name     = iv_name
                  io_question = lo_q ).
    ro_client = me.
  ENDMETHOD.

  METHOD add_question.
    DATA ls_q TYPE ty_s_question.

    ls_q-name     = iv_name.
    ls_q-question = io_question.
    INSERT ls_q INTO TABLE mt_questions.
    ro_client = me.
  ENDMETHOD.

  METHOD clear_questions.
    CLEAR mt_questions.
    ro_client = me.
  ENDMETHOD.

  METHOD evaluate.
    ro_result = execute( iv_path      = '/v1/systemone'
                         iv_state     = iv_state
                         it_questions = mt_questions ).
  ENDMETHOD.

  METHOD evaluate_permuted.
    ro_result = execute( iv_path      = '/v1/systemone/permute'
                         iv_state     = iv_state
                         it_questions = mt_questions ).
  ENDMETHOD.

  METHOD evaluate_separated.
    ro_result = execute( iv_path      = '/v1/systemone/separate'
                         iv_state     = iv_state
                         it_questions = mt_questions ).
  ENDMETHOD.

  METHOD is_true.
    DATA lt_q   TYPE ty_t_question.
    DATA ls_q   TYPE ty_s_question.
    DATA lo_q   TYPE REF TO zcl_jev_q_noul.
    DATA lo_res TYPE REF TO zcl_jev_result.

    CREATE OBJECT lo_q
      EXPORTING iv_instructions = iv_instruction.

    ls_q-name     = 'q'.
    ls_q-question = lo_q.
    INSERT ls_q INTO TABLE lt_q.

    lo_res  = execute( iv_path      = '/v1/systemone'
                       iv_state     = iv_state
                       it_questions = lt_q ).
    rv_bool = lo_res->is_noul_true( iv_key       = 'q'
                                    iv_threshold = iv_threshold ).
  ENDMETHOD.

  METHOD classify.
    DATA lt_q   TYPE ty_t_question.
    DATA ls_q   TYPE ty_s_question.
    DATA lo_q   TYPE REF TO zcl_jev_q_choice.
    DATA lo_res TYPE REF TO zcl_jev_result.

    CREATE OBJECT lo_q
      EXPORTING iv_instructions = iv_instruction
                it_criteria     = it_options.

    ls_q-name     = 'q'.
    ls_q-question = lo_q.
    INSERT ls_q INTO TABLE lt_q.

    lo_res    = execute( iv_path      = '/v1/systemone'
                         iv_state     = iv_state
                         it_questions = lt_q ).
    rv_choice = lo_res->get_choice( 'q' ).
  ENDMETHOD.

  METHOD score.
    DATA lt_q   TYPE ty_t_question.
    DATA ls_q   TYPE ty_s_question.
    DATA lo_q   TYPE REF TO zcl_jev_q_score.
    DATA lo_res TYPE REF TO zcl_jev_result.

    CREATE OBJECT lo_q
      EXPORTING iv_instructions = iv_instruction
                it_criteria     = it_levels.

    ls_q-name     = 'q'.
    ls_q-question = lo_q.
    INSERT ls_q INTO TABLE lt_q.

    lo_res   = execute( iv_path      = '/v1/systemone'
                        iv_state     = iv_state
                        it_questions = lt_q ).
    rv_score = lo_res->get_score( 'q' ).
  ENDMETHOD.

  METHOD execute.
    DATA lv_payload  TYPE string.
    DATA lv_response TYPE string.

    lv_payload = build_payload( iv_state     = iv_state
                                it_questions = it_questions ).

    lv_response = mo_http->post( iv_path    = iv_path
                                 iv_payload = lv_payload ).

    ro_result = parse_response( lv_response ).
  ENDMETHOD.

  METHOD build_payload.
    DATA lt_components TYPE cl_abap_structdescr=>component_table.
    DATA ls_component  TYPE cl_abap_structdescr=>component.
    DATA lo_struct     TYPE REF TO cl_abap_structdescr.
    DATA lr_questions  TYPE REF TO data.
    DATA ls_request    TYPE ty_s_request_payload.
    DATA lv_comp_name  TYPE string.
    FIELD-SYMBOLS <fs_question>  TYPE ty_s_question.
    FIELD-SYMBOLS <fs_questions> TYPE any.
    FIELD-SYMBOLS <fs_dest>      TYPE any.

    LOOP AT it_questions ASSIGNING <fs_question>.
      CLEAR ls_component.
      ls_component-name = to_upper( <fs_question>-name ).
      ls_component-type = cl_abap_refdescr=>get_ref_to_data( ).
      APPEND ls_component TO lt_components.
    ENDLOOP.

    lo_struct = cl_abap_structdescr=>create( lt_components ).
    CREATE DATA lr_questions TYPE HANDLE lo_struct.
    ASSIGN lr_questions->* TO <fs_questions>.

    LOOP AT it_questions ASSIGNING <fs_question>.
      lv_comp_name = to_upper( <fs_question>-name ).
      ASSIGN COMPONENT lv_comp_name OF STRUCTURE <fs_questions> TO <fs_dest>.
      IF sy-subrc = 0.
        <fs_dest> = <fs_question>-question->build( ).
      ENDIF.
    ENDLOOP.

    ls_request-model     = mv_model.
    ls_request-state     = iv_state.
    ls_request-questions = lr_questions.

    rv_payload = /ui2/cl_json=>serialize( data        = ls_request
                                          pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
  ENDMETHOD.

  METHOD parse_usage.
    FIELD-SYMBOLS <fs_usage> TYPE any.
    FIELD-SYMBOLS <fs_val>   TYPE any.

    IF ir_usage IS INITIAL.
      RETURN.
    ENDIF.

    ASSIGN ir_usage->* TO <fs_usage>.
    IF <fs_usage> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    ASSIGN COMPONENT 'INPUT_TOKENS' OF STRUCTURE <fs_usage> TO <fs_val>.
    IF <fs_val> IS ASSIGNED.
      rs_usage-input_tokens = <fs_val>.
    ENDIF.

    ASSIGN COMPONENT 'OUTPUT_TOKENS' OF STRUCTURE <fs_usage> TO <fs_val>.
    IF <fs_val> IS ASSIGNED.
      rs_usage-output_tokens = <fs_val>.
    ENDIF.
  ENDMETHOD.

  METHOD parse_choice_probabilities.
    DATA lo_prob_descr TYPE REF TO cl_abap_structdescr.
    DATA lt_prob_comps TYPE cl_abap_structdescr=>component_table.
    DATA ls_prob       TYPE zcl_jev_result=>ty_s_prob.
    FIELD-SYMBOLS <fs_prob_struct> TYPE any.
    FIELD-SYMBOLS <fs_pcomp>       TYPE cl_abap_structdescr=>component.
    FIELD-SYMBOLS <fs_pval>        TYPE any.

    IF ir_prob IS INITIAL.
      RETURN.
    ENDIF.

    ASSIGN ir_prob->* TO <fs_prob_struct>.
    IF <fs_prob_struct> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    lo_prob_descr ?= cl_abap_typedescr=>describe_by_data( <fs_prob_struct> ).
    lt_prob_comps = lo_prob_descr->get_components( ).
    LOOP AT lt_prob_comps ASSIGNING <fs_pcomp>.
      ASSIGN COMPONENT <fs_pcomp>-name OF STRUCTURE <fs_prob_struct> TO <fs_pval>.
      IF <fs_pval> IS ASSIGNED.
        CLEAR ls_prob.
        ls_prob-label = to_lower( <fs_pcomp>-name ).
        ls_prob-prob  = <fs_pval>.
        APPEND ls_prob TO rt_probs.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_answer_item.
    DATA lv_type   TYPE string.
    DATA lv_key    TYPE string.
    DATA ls_noul   TYPE zcl_jev_result=>ty_s_noul.
    DATA ls_choice TYPE zcl_jev_result=>ty_s_choice.
    DATA ls_score  TYPE zcl_jev_result=>ty_s_score.
    DATA lr_prob   TYPE REF TO data.
    FIELD-SYMBOLS <fs_aitem>    TYPE any.
    FIELD-SYMBOLS <fs_atype>    TYPE any.
    FIELD-SYMBOLS <fs_val>      TYPE any.
    FIELD-SYMBOLS <fs_conf>     TYPE any.
    FIELD-SYMBOLS <fs_prob_ref> TYPE any.

    ASSIGN ir_item->* TO <fs_aitem>.
    IF <fs_aitem> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    ASSIGN COMPONENT 'TYPE' OF STRUCTURE <fs_aitem> TO <fs_atype>.
    IF <fs_atype> IS ASSIGNED.
      lv_type = <fs_atype>.
    ENDIF.

    lv_key = to_lower( iv_name ).

    CASE lv_type.
      WHEN 'noul'.
        ASSIGN COMPONENT 'NOUL' OF STRUCTURE <fs_aitem> TO <fs_val>.
        IF <fs_val> IS ASSIGNED.
          ls_noul-key  = lv_key.
          ls_noul-prob = <fs_val>.
          INSERT ls_noul INTO TABLE ct_nouls.
        ENDIF.

      WHEN 'choice'.
        ASSIGN COMPONENT 'CHOICE' OF STRUCTURE <fs_aitem> TO <fs_val>.
        IF <fs_val> IS ASSIGNED.
          ls_choice-key    = lv_key.
          ls_choice-choice = <fs_val>.
          ASSIGN COMPONENT 'CONFIDENCE' OF STRUCTURE <fs_aitem> TO <fs_conf>.
          IF <fs_conf> IS ASSIGNED.
            ls_choice-confidence = <fs_conf>.
          ENDIF.

          ASSIGN COMPONENT 'PROBABILITIES' OF STRUCTURE <fs_aitem> TO <fs_prob_ref>.
          IF <fs_prob_ref> IS ASSIGNED AND <fs_prob_ref> IS NOT INITIAL.
            lr_prob = <fs_prob_ref>.
            ls_choice-probabilities = parse_choice_probabilities( lr_prob ).
          ENDIF.

          INSERT ls_choice INTO TABLE ct_choices.
        ENDIF.

      WHEN 'score'.
        ASSIGN COMPONENT 'SCORE' OF STRUCTURE <fs_aitem> TO <fs_val>.
        IF <fs_val> IS ASSIGNED.
          ls_score-key   = lv_key.
          ls_score-score = <fs_val>.
          ASSIGN COMPONENT 'CONFIDENCE' OF STRUCTURE <fs_aitem> TO <fs_conf>.
          IF <fs_conf> IS ASSIGNED.
            ls_score-confidence = <fs_conf>.
          ENDIF.
          INSERT ls_score INTO TABLE ct_scores.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD parse_response.
    DATA lr_data           TYPE REF TO data.
    DATA lo_ans_descr      TYPE REF TO cl_abap_structdescr.
    DATA lt_ans_components TYPE cl_abap_structdescr=>component_table.
    DATA lt_nouls          TYPE zcl_jev_result=>ty_t_noul.
    DATA lt_choices        TYPE zcl_jev_result=>ty_t_choice.
    DATA lt_scores         TYPE zcl_jev_result=>ty_t_score.
    DATA ls_usage          TYPE zcl_jev_result=>ty_s_usage.
    DATA lv_latency_ms     TYPE f.
    DATA lr_item           TYPE REF TO data.
    DATA lr_usage          TYPE REF TO data.
    FIELD-SYMBOLS <fs_root>        TYPE any.
    FIELD-SYMBOLS <fs_answers_ref> TYPE any.
    FIELD-SYMBOLS <fs_answers>     TYPE any.
    FIELD-SYMBOLS <fs_usage_ref>   TYPE any.
    FIELD-SYMBOLS <fs_acomp>       TYPE cl_abap_structdescr=>component.
    FIELD-SYMBOLS <fs_aitem_ref>   TYPE any.
    FIELD-SYMBOLS <fs_val>         TYPE any.

    /ui2/cl_json=>deserialize( EXPORTING json         = iv_json
                                         assoc_arrays = abap_true
                               CHANGING  data         = lr_data ).

    IF lr_data IS NOT INITIAL.
      ASSIGN lr_data->* TO <fs_root>.
      IF <fs_root> IS ASSIGNED.
        ASSIGN COMPONENT 'ANSWERS' OF STRUCTURE <fs_root> TO <fs_answers_ref>.
        IF <fs_answers_ref> IS ASSIGNED AND <fs_answers_ref> IS NOT INITIAL.
          ASSIGN <fs_answers_ref>->* TO <fs_answers>.
        ENDIF.

        ASSIGN COMPONENT 'USAGE' OF STRUCTURE <fs_root> TO <fs_usage_ref>.
        IF <fs_usage_ref> IS ASSIGNED AND <fs_usage_ref> IS NOT INITIAL.
          lr_usage = <fs_usage_ref>.
          ls_usage = parse_usage( lr_usage ).
        ENDIF.

        ASSIGN COMPONENT 'LATENCY_MS' OF STRUCTURE <fs_root> TO <fs_val>.
        IF <fs_val> IS ASSIGNED.
          lv_latency_ms = <fs_val>.
        ENDIF.
      ENDIF.
    ENDIF.

    IF <fs_answers> IS ASSIGNED.
      lo_ans_descr ?= cl_abap_typedescr=>describe_by_data( <fs_answers> ).
      lt_ans_components = lo_ans_descr->get_components( ).
      LOOP AT lt_ans_components ASSIGNING <fs_acomp>.
        ASSIGN COMPONENT <fs_acomp>-name OF STRUCTURE <fs_answers> TO <fs_aitem_ref>.
        IF <fs_aitem_ref> IS ASSIGNED AND <fs_aitem_ref> IS NOT INITIAL.
          lr_item = <fs_aitem_ref>.
          parse_answer_item( EXPORTING iv_name    = <fs_acomp>-name
                                       ir_item    = lr_item
                             CHANGING  ct_nouls   = lt_nouls
                                       ct_choices = lt_choices
                                       ct_scores  = lt_scores ).
        ENDIF.
      ENDLOOP.
    ENDIF.

    CREATE OBJECT ro_result
      EXPORTING it_nouls      = lt_nouls
                it_choices    = lt_choices
                it_scores     = lt_scores
                is_usage      = ls_usage
                iv_latency_ms = lv_latency_ms.
  ENDMETHOD.
ENDCLASS.
