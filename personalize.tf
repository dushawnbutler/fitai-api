
        name = "USER_ID"
        type = "string"
      },
      {
        name = "ITEM_ID"
        type = "string"
      },
      {
        name = "TIMESTAMP"
        type = "long"
      },
      {
        name = "EVENT_TYPE"
        type = "string"
      }
    ]

    version = "1.0"
  })
}

resource "awscc_personalize_dataset_group" "main" {
  name = "${var.project_name}-${var.environment}"
}

resource "awscc_personalize_dataset" "workout_interactions" {
  name              = "${var.project_name}-${var.environment}-interactions"
  dataset_group_arn = awscc_personalize_dataset_group.main.dataset_group_arn
  dataset_type      = "Interactions"
  schema_arn        = awscc_personalize_schema.workout_interactions.schema_arn
}
