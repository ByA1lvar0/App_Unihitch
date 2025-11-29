-- Agregar columna dominio a la tabla universidad
ALTER TABLE universidad 
ADD COLUMN IF NOT EXISTS dominio VARCHAR(100);

-- Actualizar dominios de las universidades existentes
UPDATE universidad SET dominio = 'udep.edu.pe' WHERE nombre LIKE '%Universidad de Piura%';
UPDATE universidad SET dominio = 'alumnos.unp.edu.pe' WHERE nombre LIKE '%Universidad Nacional de Piura%';
UPDATE universidad SET dominio = 'ucv.edu.pe' WHERE nombre LIKE '%Universidad César Vallejo%';
UPDATE universidad SET dominio = 'upn.edu.pe' WHERE nombre LIKE '%Universidad Privada del Norte%';
UPDATE universidad SET dominio = 'usmp.pe' WHERE nombre LIKE '%Universidad de San Martín de Porres%';
