{application,mutex,
             [{applications,[kernel,stdlib,elixir,logger]},
              {description,"This package implements a simple mutex as a GenServer. It allows to await\nlocked keys and handles locking multiple keys without deadlocks.\n"},
              {modules,['Elixir.Mutex','Elixir.Mutex.Lock','Elixir.Mutex.S']},
              {registered,[]},
              {vsn,"1.0.2"}]}.
