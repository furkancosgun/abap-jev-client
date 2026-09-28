# ABAP JEV Client

An ABAP client for the [TypeSafe's Jev](https://docs.typesafe.ai/introduction) decision model API.

Designed for SAP systems with full **ABAP 7.02 (v702)** downport compatibility, native `/ui2/cl_json` dynamic serialization, and a fluent API.

---

## Features

- **Fluent API**: Chain questions and evaluate in a single network roundtrip.
- **Single-Line Decision Helpers**: Quick evaluation methods for BAdIs and User-Exits (`is_true`, `classify`, `score`).
- **Type-Safe Results**: Native ABAP `abap_bool`, `f` (float), and `string` types with calibration metadata.
- **Enterprise Ready**: Supports direct URLs or SAP **SM59** RFC HTTP destinations.
- **Standardized Serialization**: Dynamic RTTI struct generation—no manual JSON string concatenation.
- **Backward Compatible**: Compatible with SAP NetWeaver 7.02 through S/4HANA.

---

## Quickstart

### 1. Fluent Multi-Question Evaluation

```abap
DATA lo_client TYPE REF TO zcl_jev_client.
DATA lo_result TYPE REF TO zcl_jev_result.
DATA lt_tones  TYPE zcl_jev_q_choice=>ty_t_criteria.
DATA lt_levels TYPE zcl_jev_q_score=>ty_t_criteria.

lo_client = zcl_jev_client=>create_by_url(
  iv_url     = 'http://127.0.0.1:8009'
  iv_api_key = 'local' ).

APPEND 'calm' TO lt_tones.
APPEND 'frustrated' TO lt_tones.
APPEND 'angry' TO lt_tones.

APPEND 'can wait' TO lt_levels.
APPEND 'this week' TO lt_levels.
APPEND 'today' TO lt_levels.

lo_client->add_noul(
  iv_name         = 'billing'
  iv_instructions = 'Is this ticket related to billing or payment?'
)->add_choice(
  iv_name         = 'tone'
  iv_instructions = 'What is the customer sentiment?'
  it_criteria     = lt_tones
)->add_score(
  iv_name         = 'urgency'
  iv_instructions = 'How urgent is this request?'
  it_criteria     = lt_levels ).

lo_result = lo_client->evaluate( 'I was charged twice on my card. Please refund immediately.' ).

IF lo_result->is_noul_true( 'billing' ) = abap_true.
  WRITE: / 'Category:', 'Billing'.
ENDIF.

WRITE: / 'Tone   :', lo_result->get_choice( 'tone' ).
WRITE: / 'Urgency:', lo_result->get_score( 'urgency' ).
```

---

### 2. Single-Line Quick Decisions

For User-Exits, BAdIs, and workflow condition checks:

```abap
" 1. Boolean check (returns abap_bool)
IF lo_client->is_true(
     iv_state       = lv_order_notes
     iv_instruction = 'Is this an express shipping request?' ) = abap_true.
  " Set expedited delivery
ENDIF.

" 2. Classification (returns string)
lv_category = lo_client->classify(
  iv_state       = lv_ticket_body
  iv_instruction = 'What product category is this?'
  it_options     = lt_categories ).

" 3. Numerical rating / score (returns float)
lv_risk = lo_client->score(
  iv_state       = lv_vendor_notes
  iv_instruction = 'Rate the supplier delivery risk'
  it_levels      = lt_risk_levels ).
```

---

### 3. Enterprise SM59 RFC Destination

In production SAP environments, manage endpoints, credentials, and SSL certificates centrally via transaction `SM59`:

```abap
lo_client = zcl_jev_client=>create_by_destination(
  iv_destination = 'JEV_AI_SERVER'
  iv_model       = 'kev-latest'
  iv_timeout     = 30 ).
```

---

## API Reference

### `zcl_jev_client`

| Method | Description |
|---|---|
| `create_by_url( iv_url, iv_api_key, iv_model, iv_timeout )` | Instantiates client with a direct HTTP URL. |
| `create_by_destination( iv_destination, iv_model, iv_timeout )` | Instantiates client with an SM59 destination. |
| `set_model( iv_model )` | Switches model checkpoint (e.g. `kev-0.8b`, `kev-4b`, `kev-27b`). |
| `add_noul( iv_name, iv_instructions )` | Adds a yes/no boolean probability question. |
| `add_choice( iv_name, iv_instructions, it_criteria )` | Adds a categorical choice question. |
| `add_score( iv_name, iv_instructions, it_criteria )` | Adds an ordinal scoring question. |
| `clear_questions()` | Resets the queued question set. |
| `evaluate( iv_state )` | Evaluates queued questions (`POST /v1/systemone`). |
| `evaluate_permuted( iv_state )` | Evaluates with permutation debiasing (`POST /v1/systemone/permute`). |
| `evaluate_separated( iv_state )` | Evaluates questions independently (`POST /v1/systemone/separate`). |
| `is_true( iv_state, iv_instruction, iv_threshold )` | Runs a one-off boolean check. |
| `classify( iv_state, iv_instruction, it_options )` | Runs a one-off category selection. |
| `score( iv_state, iv_instruction, it_levels )` | Runs a one-off score evaluation. |

---

### `zcl_jev_result`

| Method | Return Type | Description |
|---|---|---|
| `is_noul_true( iv_key, iv_threshold )` | `abap_bool` | Returns `abap_true` if probability $\ge$ threshold (default `0.5`). |
| `get_noul( iv_key )` | `f` | Calibrated probability in $[0.0, 1.0]$. |
| `get_choice( iv_key )` | `string` | Highest-probability choice label. |
| `get_choice_confidence( iv_key )` | `f` | Confidence score for the selected label. |
| `get_choice_probabilities( iv_key )` | `ty_t_prob` | Full distribution table (`label`, `prob`). |
| `get_score( iv_key )` | `f` | Continuous weighted score across levels. |
| `get_score_confidence( iv_key )` | `f` | Confidence score for the continuous score. |
| `get_latency_ms()` | `f` | Server-side execution latency in milliseconds. |
| `get_input_tokens()` | `i` | Prompt token count. |
| `get_output_tokens()` | `i` | Output token count. |
| `get_total_tokens()` | `i` | Total token count. |

---

## File Structure

```text
src/
├── zcl_jev_client.clas.abap    # Main client orchestrator & fluent builder
├── zcl_jev_http.clas.abap      # HTTP transport adapter (URL & SM59)
├── zif_jev_http.intf.abap      # HTTP client interface contract
├── zcl_jev_result.clas.abap    # Type-safe response Value Object
├── zif_jev_question.intf.abap  # Question payload builder contract
├── zcl_jev_q_noul.clas.abap    # Noul question model
├── zcl_jev_q_choice.clas.abap  # Choice question model
├── zcl_jev_q_score.clas.abap   # Score question model
├── zcx_jev_error.clas.abap     # Exception class
└── zjev_demo.prog.abap         # Executable demo program
```

---

## Testing & Linting

```bash
# Run test suite (linter + transpiled demo run against live server)
npm run test

# Run abaplint syntax & downport validation
npm run lint

# Auto-fix linting issues
npm run fix
```

---

## License

MIT