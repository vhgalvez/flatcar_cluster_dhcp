Crea un nuevo repositorio en GitHub para la versión del proyecto.

Clona el repositorio original a tu máquina local:

bash
Copy code
git clone https://github.com/usuario-original/repositorio-original.git
Cambia al directorio del repositorio clonado:

bash
Copy code
cd repositorio-original
Cambia el origen (remote) a tu nuevo repositorio:

arduino
Copy code
git remote set-url origin https://github.com/tu-usuario/nuevo-repositorio.git
Empuja el código al nuevo repositorio:

perl
Copy code
git push -u origin master
Esto duplicará el proyecto en el nuevo repositorio, permitiéndote hacer cambios sin afectar el repositorio original.