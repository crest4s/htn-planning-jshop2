(defproblem problem emergency
(
  (at drone1 depot)
  (libre drone1 brazo1)
  (at crate1 depot)
  (tipo crate1 food)
  (at crate2 depot)
  (tipo crate2 medicine)
  (at person1 loc1)
  (necesita person1 food)
  (necesita person1 medicine)
  (at person2 loc1)
)
(
  (enviar-todo)
)
)
