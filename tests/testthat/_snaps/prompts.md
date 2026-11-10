# the rendered judgeable prompt is stable

    Code
      liminal2::liminal_prompts("Build us a churn model.")$judgeable
    Output
      [1] | You are scoring one dimension of the liminal space between a business
          | ask and a data-based solution. The liminal space is the gap between
          | what the business asked for and what a data-based solution can
          | deliver. You score only the dimension below, not the overall gap.
          | 
          | ## Dimension
          | 
          | Judgeable - an external authority can adjudicate.
          | 
          | Question a business owner can answer: Who can say, independently,
          | that this worked?
          | 
          | Question a data scientist can answer: Is there an adjudicator with a
          | defined procedure?
          | 
          | Evidence: rubric - exists, independent, has a procedure.
          | 
          | ## Scale
          | 
          | Return an integer from 0 to 10. 0 means the dimension poses no
          | obstacle (the smallest possible liminal space). 10 means the dimension
          | is maximally obstructed (the largest possible liminal space).
          | 
          | ## Anchor cases
          | 
          | Score 2 (small space): An independent party with a written procedure
          | can verify whether the output satisfies the ask.
          | 
          | Score 5 (moderate space): A reviewer exists but the procedure is
          | informal or partly subjective.
          | 
          | Score 8 (large space): No independent arbiter or agreed procedure
          | exists; only the supplier can assert success.
          | 
          | ## What counts
          | 
          | Score only whether an independent party with a verification
          | procedure exists. Do not score the clarity of the ask, the
          | business's definition of success, or whether a baseline has been
          | agreed: those belong to other dimensions.
          | 
          | An adjudicator can exist even when the ask is vague. An auditor, a
          | regulator, an independent reviewer, or a written model-validation
          | procedure counts. If the situation implies one, do not score above
          | 4 merely because the ask is ambiguous.
          | 
          | ## How to score
          | 
          | 1. Name the independent party, if any.
          | 2. Name the procedure, if any, and whether it is written.
          | 3. Externally defined labels and regulated contexts usually imply
          |    an external procedure; the absence of a business baseline does
          |    not remove it.
          | 4. Match to the anchors and interpolate.
          | 5. Reserve 0-1 for a formally audited output with a written
          |    procedure, and 9-10 for a case where only the supplier can assert
          |    success.
          | 
          | ## Input
          | 
          | Business ask:
          | 
          | ```
          | Build us a churn model.
          | ```
          | 
          | Situation and context:
          | 
          | ```
          | No additional situation was supplied.
          | ```
          | 
          | ## Output
          | 
          | Return only the integer. No explanation, no units, no decimals.

