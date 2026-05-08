(defdomain emergency2 (

  ;; ==========================================
  ;; 1. AXIOMAS (Refactorizados para JSHOP2)
  ;; ==========================================
  
  (:- (necesidad-total ?l ?total)
      (and (necesidad ?l comida ?nc)
           (necesidad ?l medicina ?nm)
           (assign ?total (call + ?nc ?nm)))
  )

  ;; HELPER: ¿Hay otra localización que tenga MÁS necesidad que esta?
  (:- (hay-loc-con-mas-necesidad ?total)
      (and (necesidad-total ?l2 ?t2)
           (call > ?t2 ?total))
  )

  ;; AXIOMA LIMPIO: Es la que más necesidad tiene si no hay otra que la supere
  (:- (max-loc-necesidad ?l ?total)
      (and (necesidad-total ?l ?total)
           (call > ?total 0)
           (not (hay-loc-con-mas-necesidad ?total)))
  )

  ;; HELPER: ¿Hay un transportador que también sirva y sea más pequeño?
  (:- (hay-trans-suficiente-mas-pequeno ?need ?cap)
      (and (at-trans ?t2 depot)
           (capacidad-trans ?t2 ?cap2)
           (call >= ?cap2 ?need)
           (call < ?cap2 ?cap))
  )

  ;; AXIOMA LIMPIO
  (:- (mejor-trans-suficiente ?t ?cap ?need)
      (and (at-trans ?t depot)
           (capacidad-trans ?t ?cap)
           (call >= ?cap ?need)
           (not (hay-trans-suficiente-mas-pequeno ?need ?cap)))
  )

  ;; HELPER: ¿Hay un transportador insuficiente pero que sea más grande?
  (:- (hay-trans-insuficiente-mas-grande ?need ?cap)
      (and (at-trans ?t2 depot)
           (capacidad-trans ?t2 ?cap2)
           (call < ?cap2 ?need)
           (call > ?cap2 ?cap))
  )

  ;; AXIOMA LIMPIO
  (:- (mejor-trans-insuficiente ?t ?cap ?need)
      (and (at-trans ?t depot)
           (capacidad-trans ?t ?cap)
           (call < ?cap ?need)
           (not (hay-trans-insuficiente-mas-grande ?need ?cap)))
  )


  ;; ==========================================
  ;; 2. OPERADORES
  ;; ==========================================

  (:operator (!vuelo ?d ?origen ?destino ?cap_trans)
    ((at ?d ?origen))
    ((at ?d ?origen))
    ((at ?d ?destino))
    (call + 50 (call / ?cap_trans 10))
  )

  (:operator (!coger-transportador ?d ?t ?l)
    ((at ?d ?l) (at-trans ?t ?l) (dron-libre ?d))
    ((at-trans ?t ?l) (dron-libre ?d))
    ((llevando-trans ?d ?t))
  )

  (:operator (!dejar-transportador ?d ?t ?l)
    ((at ?d ?l) (llevando-trans ?d ?t))
    ((llevando-trans ?d ?t))
    ((at-trans ?t ?l) (dron-libre ?d))
  )

  (:operator (!cargar ?t ?tipo ?cant ?l)
    ((at-trans ?t ?l) (cajas ?l ?tipo ?c_suelo) (carga ?t ?tipo ?c_actual) (call > ?cant 0))
    ((cajas ?l ?tipo ?c_suelo) (carga ?t ?tipo ?c_actual))
    ((cajas ?l ?tipo (call - ?c_suelo ?cant)) (carga ?t ?tipo (call + ?c_actual ?cant)))
  )

  (:operator (!entregar ?t ?tipo ?cant ?l)
    ((at-trans ?t ?l) (necesidad ?l ?tipo ?n_actual) (carga ?t ?tipo ?c_actual) (call > ?cant 0))
    ((necesidad ?l ?tipo ?n_actual) (carga ?t ?tipo ?c_actual))
    ((necesidad ?l ?tipo (call - ?n_actual ?cant)) (carga ?t ?tipo (call - ?c_actual ?cant)))
  )

  (:operator (!cargar-suelta ?d ?tipo ?l)
    ((at ?d ?l) (cajas ?l ?tipo ?c_suelo) (dron-libre ?d) (call > ?c_suelo 0))
    ((cajas ?l ?tipo ?c_suelo) (dron-libre ?d))
    ((cajas ?l ?tipo (call - ?c_suelo 1)) (llevando-suelta ?d ?tipo))
  )

  (:operator (!entregar-suelta ?d ?tipo ?l)
    ((at ?d ?l) (necesidad ?l ?tipo ?n_actual) (llevando-suelta ?d ?tipo))
    ((necesidad ?l ?tipo ?n_actual) (llevando-suelta ?d ?tipo))
    ((necesidad ?l ?tipo (call - ?n_actual 1)) (dron-libre ?d))
  )

  ;; ==========================================
  ;; 3. MÉTODOS
  ;; ==========================================

  (:method (enviar-todo)
    
    ;; PRIORIDAD 0: Ruta Multiparada (Atender 2 localizaciones en el mismo viaje)
    hay_multiparada
    (
      (max-loc-necesidad ?l1 ?t1)
      (necesidad-total ?l2 ?t2)
      (call > ?t2 0)
      (not (call = ?l1 ?l2)) ;; Comprueba que l2 sea una localización distinta a l1
      (assign ?total_need (call + ?t1 ?t2))
      (at dron1 ?ld)
      (dron-libre dron1)
      ;; Busca si hay algún transportador que pueda con la suma de AMBAS necesidades
      (mejor-trans-suficiente ?t ?cap ?total_need)
      (necesidad ?l1 comida ?nc1)
      (necesidad ?l1 medicina ?nm1)
      (necesidad ?l2 comida ?nc2)
      (necesidad ?l2 medicina ?nm2)
    )
    (
      (atender-multiparada ?l1 ?l2 ?t ?cap ?nc1 ?nm1 ?nc2 ?nm2)
      (enviar-todo) ;; Tras la ruta, vuelve a evaluar si quedan necesidades
    )

    ;; PRIORIDAD 1: Viaje normal a la localización más necesitada
    hay_necesidad
    (
      (max-loc-necesidad ?l ?total)
    )
    ((atender-localizacion ?l ?total) (enviar-todo))

    ;; BASE: Terminado
    terminado
    ()
    ()
  )

  ;; MÉTODO NUEVO: Ejecuta la ruta multi-parada
  (:method (atender-multiparada ?l1 ?l2 ?t ?cap ?nc1 ?nm1 ?nc2 ?nm2)
    hacer_ruta
    (
      (at dron1 ?ld)
    )
    (
      (ir-a dron1 ?ld depot 0)
      ;; 1. Carga la mezcla para la primera localización
      (carga-si-necesario ?t comida ?nc1 depot)
      (carga-si-necesario ?t medicina ?nm1 depot)
      ;; 2. Sigue cargando la mezcla para la segunda localización
      (carga-si-necesario ?t comida ?nc2 depot)
      (carga-si-necesario ?t medicina ?nm2 depot)
      (!coger-transportador dron1 ?t depot)
      
      ;; 3. Vuela al primer destino y entrega
      (ir-a dron1 depot ?l1 ?cap)
      (!dejar-transportador dron1 ?t ?l1)
      (entrega-si-necesario ?t comida ?nc1 ?l1)
      (entrega-si-necesario ?t medicina ?nm1 ?l1)
      (!coger-transportador dron1 ?t ?l1)
      
      ;; 4. Vuela DIRECTO al segundo destino (Sin pasar por depot)
      (ir-a dron1 ?l1 ?l2 ?cap)
      (!dejar-transportador dron1 ?t ?l2)
      (entrega-si-necesario ?t comida ?nc2 ?l2)
      (entrega-si-necesario ?t medicina ?nm2 ?l2)
      (!coger-transportador dron1 ?t ?l2)
      
      ;; 5. Regresa al depósito
      (ir-a dron1 ?l2 depot ?cap)
      (!dejar-transportador dron1 ?t depot)
    )
  )

  (:method (atender-localizacion ?l ?total_need)
    
    ;; PRIORIDAD 1: Queda exactamente 1 caja suelta (Más barato llevarla a mano)
    una_caja_suelta_comida
    (
      (at dron1 ?ld)
      (dron-libre dron1)
      (call = ?total_need 1)
      (necesidad ?l comida ?nc)
      (call = ?nc 1)
    )
    (
      (ir-a dron1 ?ld depot 0)
      (!cargar-suelta dron1 comida depot)
      (ir-a dron1 depot ?l 0)
      (!entregar-suelta dron1 comida ?l)
    )

    una_caja_suelta_medicina
    (
      (at dron1 ?ld)
      (dron-libre dron1)
      (call = ?total_need 1)
      (necesidad ?l medicina ?nm)
      (call = ?nm 1)
    )
    (
      (ir-a dron1 ?ld depot 0)
      (!cargar-suelta dron1 medicina depot)
      (ir-a dron1 depot ?l 0)
      (!entregar-suelta dron1 medicina ?l)
    )

    ;; PRIORIDAD 2: Hay un transportador SUFICIENTE
    con_trans_suficiente
    (
      (at dron1 ?ld)
      (dron-libre dron1)
      (mejor-trans-suficiente ?t ?cap ?total_need)
      (necesidad ?l comida ?nc)
      (necesidad ?l medicina ?nm)
    )
    (
      (ir-a dron1 ?ld depot 0)
      (carga-si-necesario ?t comida ?nc depot)
      (carga-si-necesario ?t medicina ?nm depot)
      (!coger-transportador dron1 ?t depot)
      (ir-a dron1 depot ?l ?cap)
      (!dejar-transportador dron1 ?t ?l)
      (entrega-si-necesario ?t comida ?nc ?l)
      (entrega-si-necesario ?t medicina ?nm ?l)
      (!coger-transportador dron1 ?t ?l)
      (ir-a dron1 ?l depot ?cap)
      (!dejar-transportador dron1 ?t depot)
    )

    ;; PRIORIDAD 3: Transportador INSUFICIENTE
    con_trans_insuficiente
    (
      (at dron1 ?ld)
      (dron-libre dron1)
      (mejor-trans-insuficiente ?t ?cap ?total_need)
      (necesidad ?l comida ?nc)
      (necesidad ?l medicina ?nm)
    )
    (
      (ir-a dron1 ?ld depot 0)
      (carga-maxima ?t ?cap ?nc ?nm depot)
      (!coger-transportador dron1 ?t depot)
      (ir-a dron1 depot ?l ?cap)
      (!dejar-transportador dron1 ?t ?l)
      (descarga-todo ?t ?l)
      (!coger-transportador dron1 ?t ?l)
      (ir-a dron1 ?l depot ?cap)
      (!dejar-transportador dron1 ?t depot)
    )

    ;; PRIORIDAD 4: Sin transportador (1 a 1)
    sin_trans_comida
    (
      (at dron1 ?ld)
      (dron-libre dron1)
      (not (at-trans ?t depot))
      (necesidad ?l comida ?nc)
      (call > ?nc 0)
    )
    (
      (ir-a dron1 ?ld depot 0)
      (!cargar-suelta dron1 comida depot)
      (ir-a dron1 depot ?l 0)
      (!entregar-suelta dron1 comida ?l)
    )

    sin_trans_medicina
    (
      (at dron1 ?ld)
      (dron-libre dron1)
      (not (at-trans ?t depot))
      (necesidad ?l medicina ?nm)
      (call > ?nm 0)
    )
    (
      (ir-a dron1 ?ld depot 0)
      (!cargar-suelta dron1 medicina depot)
      (ir-a dron1 depot ?l 0)
      (!entregar-suelta dron1 medicina ?l)
    )
  )

  ;; --- Métodos Auxiliares ---
  
  (:method (carga-maxima ?t ?cap ?nc ?nm ?l)
    solo_comida
    ((call <= ?cap ?nc))
    ((!cargar ?t comida ?cap ?l))

    comida_y_medicina
    ((call > ?cap ?nc))
    ((carga-si-necesario ?t comida ?nc ?l)
     (carga-si-necesario ?t medicina (call - ?cap ?nc) ?l))
  )

  (:method (descarga-todo ?t ?l)
    hacer_descarga
    (
      (carga ?t comida ?cc)
      (carga ?t medicina ?cm)
    )
    (
      (entrega-si-necesario ?t comida ?cc ?l)
      (entrega-si-necesario ?t medicina ?cm ?l)
    )
  )

  (:method (carga-si-necesario ?t ?tipo ?cant ?l)
    hacer_carga ((call > ?cant 0)) ((!cargar ?t ?tipo ?cant ?l))
    no_hace_falta ((call <= ?cant 0)) ()
  )

  (:method (entrega-si-necesario ?t ?tipo ?cant ?l)
    hacer_entrega ((call > ?cant 0)) ((!entregar ?t ?tipo ?cant ?l))
    no_hace_falta ((call <= ?cant 0)) ()
  )

  (:method (ir-a ?d ?origen ?destino ?cap)
    ya_estoy ((at ?d ?destino)) ()
    volar ((not (at ?d ?destino))) ((!vuelo ?d ?origen ?destino ?cap))
  )
))