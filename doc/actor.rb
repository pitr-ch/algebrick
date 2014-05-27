Work = Algebrick.type do
  fields key: String, work: Proc
end

Finished = Algebrick.type do
  fields key: String, result: Object, worker: Worker
end

class Worker < AbstractActor
  def initialize(executor)
    super()
    @executor = executor
  end

  def on_message(message)
    match message,
          Work.(~any, ~any) >-> key, work do
            @executor.tell Finished[key, work.call, self]
          end
  end
end
