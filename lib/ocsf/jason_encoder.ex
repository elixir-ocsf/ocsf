defimpl Jason.Encoder, for: OCSF.Event do
  def encode(event, opts) do
    event
    |> OCSF.Serializer.to_map()
    |> Jason.Encode.map(opts)
  end
end
