(defdomain emergency (

  ;; --- OPERADORES ---

  (:operator (!vuelo ?d ?o ?dest)
    ((at ?d ?o))        ; Precondición
    ((at ?d ?o))        ; Borrado
    ((at ?d ?dest))     ; Añadido
  )

  (:operator (!recoger ?d ?b ?c ?l)
    ((at ?d ?l) (at ?c ?l) (libre ?d ?b))
    ((at ?c ?l) (libre ?d ?b))
    ((en-brazo ?d ?b ?c))
  )

  (:operator (!entregar ?d ?b ?c ?p ?l ?cont)
    ((at ?d ?l) (at ?p ?l) (en-brazo ?d ?b ?c) (tipo ?c ?cont) (necesita ?p ?cont))
    ((en-brazo ?d ?b ?c) (necesita ?p ?cont))
    ((libre ?d ?b) (tiene ?p ?cont))
  )

  ;; --- MÉTODOS ---

  ;; Caso base: todas las necesidades han sido atendidas
  ;; Caso recursivo: hay alguna persona que necesita algo y aún no lo tiene
  ;; Estructura: (:method (nombre-tarea args) etiqueta-opcional (precondiciones) (subtareas))
  (:method (enviar-todo)
    pendiente
    ((necesita ?p ?cont) (not (tiene ?p ?cont)))
    ((atender-p ?p ?cont) (enviar-todo))  ;; Las subtareas se listan como una secuencia

    fin
    ()  ;; Precondición vacía (caso base)
    ()  ;; Lista de subtareas vacía
  )

  ;; Entrega una caja de tipo ?cont a la persona ?p
  (:method (atender-p ?p ?cont)

    ;; CASO 1: el dron ya está en el depósito
    ya_en_depot
    ((at ?p ?l) (at ?c depot) (tipo ?c ?cont) (at ?d depot) (libre ?d ?b))
    ((!recoger ?d ?b ?c depot)
     (!vuelo ?d depot ?l)
     (!entregar ?d ?b ?c ?p ?l ?cont))

    ;; CASO 2: el dron está en otra localización y debe ir al depósito primero
    necesita_vuelo
    ((at ?p ?l) (at ?c depot) (tipo ?c ?cont) (at ?d ?ld) (not (= ?ld depot)) (libre ?d ?b))
    ((!vuelo ?d ?ld depot)
     (!recoger ?d ?b ?c depot)
     (!vuelo ?d depot ?l)
     (!entregar ?d ?b ?c ?p ?l ?cont))
  )
))
