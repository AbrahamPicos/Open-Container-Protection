# Open Container Protection.

[English](README.md) | Español

Protege los contenedores donde reaparece el botín, para que los jugadores no puedan moverlos ni romperlos.

Este mod está diseñado para proteger todos los contenedores que no hayan sido colocados por los jugadores; por lo tanto, a diferencia de otros mods de protección de contenedores, protegerá cualquier contenedor en cualquier parte del mapa. Sin embargo, también permite configurar excepciones específicas para cualquier contenedor del juego.

Surgió como una alternativa libre a los mods de protección de contenedores existentes. Por lo tanto, a diferencia de esos mods, puedes hacer lo que quieras con él sin necesidad de dar crédito a los colaboradores.

Aunque está inspirado en el mod "Container Protection" de iLusioN, ha sido escrito completamente desde cero, siguiendo un enfoque radicalmente diferente.

Hasta la fecha, se ha traducido a todas las variantes del español y al inglés.

## Características:

1. Extremadamente simple, ligero y seguro.
    - Programación defensiva.
    - No requiere configuración.
    - Probado en un servidor dedicado.
    - Protección del lado del servidor.
    - Caché de clases, métodos, y tablas.
    - Seguro de agregar/quitar con guardados existentes.
    - Consideraciones para contenedores con múltiples sprites.

3. Protección de contenedores en:
    - Interiores, en cualquier habitación.
    - Exteriores, incluso en lugares remotos.

2. Protección de contenedores contra:
    - Rotar.
    - Recoger.
    - Desmantelar.
    - Destruir con una almádena.

4. Excepciones a la protección de contenedores si:
    - Un jugador los colocó.
    - Están dentro del refugio del jugador.
    - El jugador es un administrador que usa trucos.
    - Existe una excepción personalizada para su tipo.

También protege los surtidores de gasolina.

## Opciones de sandbox:

1. Permitir en refugios:
    - Este mod te permitirá mover o romper los contenedores donde reaparece el botín, siempre y cuando estén ubicados dentro de tu refugio.
    - Predeterminado: Habilitada.

2. Tiempo de espera del refugio:
    - Una vez transcurrido este tiempo (en minutos), este mod te permitirá mover o romper los contenedores donde reaparece el botín dentro de tu nuevo refugio.
    - Esto solo funciona si la opción "Permitir en refugios" está activada.
    - Predeterminado: 20.

3. Permitir en interiores de vehículos:
    - Este mod te permitirá mover o romper los contenedores donde reaparece el botín, siempre y cuando se encuentren dentro de un vehículo (mod Project RV Interior).
    - Esto dejará todos los contenedores situados por encima de x:22500,y:12000 totalmente desprotegidos.
    - Predeterminado: Deshabilitada.

4. Excepciones personalizadas:
    - Este mod te permitirá mover o romper los contenedores donde reaparece el botín, siempre que el nombre de su sprite coincida con alguno de los nombres (separados por comas) listados aquí. Todas sus caras y cuadrícula multi-sprite se detectarán automáticamente, por lo que —a menos que alguno de tus mods reemplace los sprites (como el mod "Open All Containers"), caso en el que tal vez debas añadir también nombres alternativos— solo necesitas agregar un nombre por contenedor.
    - Aunque se recomienda añadir nombres específicos para un mayor control, también es posible añadir excepciones por categoría. Por ejemplo, al introducir "appliances", se excluirán todos los contenedores cuyos nombres de sprite incluyan "appliances".
    - Predeterminado: "".

##

La forma recomendada de añadir y eliminar excepciones personalizadas es a través de la opción del menú contextual del mundo (haciendo clic con el botón derecho directamente sobre el contenedor), pero no podrás verla a menos que tengas un rol con la capacidad `SandboxOptions`.

Los trucos necesarios para sortear las restricciones del mod son:

- `BuildCheat`: Para destruir.
- `MovablesCheat`: Para rotar, recoger, y desmantelar.

##

Este mod es 100% creado por humanos y actualmente no se aceptan contribuciones de IA. Se publica bajo la licencia CC0-1.0 y solo es compatible con la última versión de Project Zomboid: 42.21.

Última versión probada de Project Zomboid: 42.21.0

Página de Steam Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3774828917
