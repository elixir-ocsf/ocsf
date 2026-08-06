defmodule OCSF.EventFixtures do
  @moduledoc false

  def valid_event_attrs do
    [
      metadata: %OCSF.Metadata{
        uid: OCSF.UUID.v7_string(),
        version: "1.9.0",
        product: %OCSF.Product{name: "Test"}
      },
      time: DateTime.utc_now(),
      category_uid: 3,
      class_uid: 3002,
      type_uid: 300_201,
      activity_id: 1,
      severity_id: 1,
      status_id: 1,
      user: %OCSF.User{uid: "test-user"}
    ]
  end

  def valid_event do
    {:ok, event} = OCSF.Event.new(valid_event_attrs())
    event
  end
end
