(defdomain emergencia (
  ;; --- OPERADORES ---
  (:operator (!vuelo ?d ?o ?dest)
    ((at ?d ?o))
    ((at ?d ?o))
    ((at ?d ?dest))
  )

  (:operator (!recoger ?d ?b ?c ?l)
    ((at ?d ?l) (at ?c ?l) (libre ?d ?b))
    ((at ?c ?l) (libre ?d ?b))
    ((en-brazo ?d ?b ?c))
  )

  (:operator (!entregar ?d ?b ?c ?p ?l ?cont)
    ((at ?d ?l) (at ?p ?l) (en-brazo ?d ?b ?c) (tipo ?c ?cont))
    ((en-brazo ?d ?b ?c))
    ((libre ?d ?b) (tiene ?p ?cont))
  )

  ;; --- MÉTODOS ---

  ;; 1. MAIN LOOP: Toma de decisiones de alto nivel
  (:method (enviar-todo)
    ;; PRIORIDAD 1: Si llevamos algo encima que alguien necesita, repártelo primero
    entregar_lo_que_llevamos
    (
      (necesita ?p ?cont)
      (not (tiene ?p ?cont))
      (en-brazo ?d ?b ?c)
      (tipo ?c ?cont)
    )
    ((entregar_carga ?d) (enviar-todo))

    ;; PRIORIDAD 2: Si hay necesidades y la caja útil está en el suelo, y además
    ;; EL DRON TIENE UN BRAZO LIBRE, ve a recogerla.
    recoger_nueva_carga
    (
      (necesita ?p ?cont)
      (not (tiene ?p ?cont))
      (at ?c depot)
      (tipo ?c ?cont)
      (at ?d ?ld)
      (libre ?d ?b) ;; ¡CRÍTICO! Esto evita que entre en bucle si tiene los brazos ocupados
    )
    ((ir-a ?d ?ld depot) (cargar ?d) (entregar_carga ?d) (enviar-todo))

    ;; CASO BASE: No hay nada más que hacer o nos hemos quedado sin recursos/brazos
    terminado
    ()
    ()
  )

  ;; 2. CARGAR DRON: Recoge todas las cajas útiles que pueda hasta llenar sus brazos
  (:method (cargar ?d)
    recoger_caja
    (
      (libre ?d ?b)
      (at ?c depot)
      (tipo ?c ?cont)
      (necesita ?p ?cont)
      (not (tiene ?p ?cont))
    )
    ((!recoger ?d ?b ?c depot) (cargar ?d))

    fin_carga
    ()
    ()
  )

  ;; 3. ENTREGAR CARGA: Vuela a las localizaciones y vacía todos los brazos útiles
  (:method (entregar_carga ?d)
    entregar_caja
    (
      (en-brazo ?d ?b ?c)
      (tipo ?c ?cont)
      (necesita ?p ?cont)
      (not (tiene ?p ?cont))
      (at ?p ?l)
      (at ?d ?ld)
    )
    ((ir-a ?d ?ld ?l) (!entregar ?d ?b ?c ?p ?l ?cont) (entregar_carga ?d))

    fin_entrega
    ()
    ()
  )

  ;; 4. MOVIMIENTO: Solo vuela si realmente necesita desplazarse
  (:method (ir-a ?d ?origen ?destino)
    ya_estoy_aqui
    ((at ?d ?destino))
    ()

    tengo_que_volar
    ((not (at ?d ?destino)))
    ((!vuelo ?d ?origen ?destino))
  )
))