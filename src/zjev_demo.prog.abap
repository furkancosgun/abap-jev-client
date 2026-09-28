REPORT zjev_demo.

CLASS lcl_app DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS run.
ENDCLASS.


CLASS lcl_app IMPLEMENTATION.
  METHOD run.
    DATA lo_client      TYPE REF TO zcl_jev_client.
    DATA lt_crit_choice TYPE zcl_jev_q_choice=>ty_t_criteria.
    DATA lt_crit_score  TYPE zcl_jev_q_score=>ty_t_criteria.
    DATA lo_result      TYPE REF TO zcl_jev_result.
    DATA lx_error       TYPE REF TO zcx_jev_error.
    DATA lv_is_billing  TYPE abap_bool.
    DATA lv_bill_prob   TYPE f.
    DATA lv_tone        TYPE string.
    DATA lv_tone_conf   TYPE f.
    DATA lt_probs       TYPE zcl_jev_result=>ty_t_prob.
    DATA lv_urgency     TYPE f.
    DATA lv_latency     TYPE f.
    DATA lv_tokens      TYPE i.
    DATA lv_err_txt     TYPE string.
    FIELD-SYMBOLS <fs_prob> TYPE zcl_jev_result=>ty_s_prob.

    lo_client = zcl_jev_client=>create_by_url( iv_url     = 'http://127.0.0.1:8009'
                                               iv_api_key = 'local'
                                               iv_model   = 'kev-latest'
                                               iv_timeout = 30 ).

    APPEND 'calm' TO lt_crit_choice.
    APPEND 'frustrated' TO lt_crit_choice.
    APPEND 'angry' TO lt_crit_choice.

    APPEND 'can wait' TO lt_crit_score.
    APPEND 'this week' TO lt_crit_score.
    APPEND 'today' TO lt_crit_score.

    TRY.
        WRITE / '=== 1. Fluent Multi-Question Evaluation ==='.
        lo_client->add_noul( iv_name         = 'billing'
                             iv_instructions = 'Is this ticket about billing?' ).
        lo_client->add_choice( iv_name         = 'tone'
                               iv_instructions = 'What is the customer''s tone?'
                               it_criteria     = lt_crit_choice ).
        lo_client->add_score( iv_name         = 'urgency'
                              iv_instructions = 'How urgent is this ticket?'
                              it_criteria     = lt_crit_score ).

        lo_result = lo_client->evaluate( 'I was charged twice. Please fix this ASAP.' ).

        lv_is_billing = lo_result->is_noul_true( 'billing' ).
        lv_bill_prob  = lo_result->get_noul( 'billing' ).
        WRITE: / 'Is Billing?  : ', lv_is_billing, ' (Prob: ', lv_bill_prob, ')'.

        lv_tone      = lo_result->get_choice( 'tone' ).
        lv_tone_conf = lo_result->get_choice_confidence( 'tone' ).
        WRITE: / 'Tone         : ', lv_tone, ' (Confidence: ', lv_tone_conf, ')'.

        lt_probs = lo_result->get_choice_probabilities( 'tone' ).
        LOOP AT lt_probs ASSIGNING <fs_prob>.
          WRITE: / '  - Label: ', <fs_prob>-label, ' -> Prob: ', <fs_prob>-prob.
        ENDLOOP.

        lv_urgency = lo_result->get_score( 'urgency' ).
        WRITE: / 'Urgency Score: ', lv_urgency.

        lv_latency = lo_result->get_latency_ms( ).
        lv_tokens  = lo_result->get_total_tokens( ).
        WRITE: / 'Latency (ms) : ', lv_latency.
        WRITE: / 'Total Tokens : ', lv_tokens.

        WRITE / '=== 2. Single-Line Quick Decisions ==='.
        lv_is_billing = lo_client->is_true( iv_state       = 'I was charged twice. Please fix this ASAP.'
                                            iv_instruction = 'Is this ticket about billing?' ).
        WRITE: / 'Quick is_true  : ', lv_is_billing.

        lv_tone = lo_client->classify( iv_state       = 'I was charged twice. Please fix this ASAP.'
                                       iv_instruction = 'What is the customer''s tone?'
                                       it_options     = lt_crit_choice ).
        WRITE: / 'Quick classify : ', lv_tone.

        lv_urgency = lo_client->score( iv_state       = 'I was charged twice. Please fix this ASAP.'
                                       iv_instruction = 'How urgent is this ticket?'
                                       it_levels      = lt_crit_score ).
        WRITE: / 'Quick score    : ', lv_urgency.

      CATCH zcx_jev_error INTO lx_error.
        lv_err_txt = lx_error->get_text( ).
        WRITE: / 'Error: ', lv_err_txt.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  lcl_app=>run( ).
