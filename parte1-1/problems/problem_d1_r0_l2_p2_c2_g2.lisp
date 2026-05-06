(defproblem problem emergency
(
  (at drone1 depot)
  (libre drone1 brazo1)
  (libre drone1 brazo2)
  (at crate1 depot)
  (tipo crate1 food)
  (at crate2 depot)
  (tipo crate2 medicine)
  (at person1 loc1)
  (at person2 loc1)
  (necesita person2 food)
  (necesita person2 medicine)
)
(
  (enviar-todo)
)
)
