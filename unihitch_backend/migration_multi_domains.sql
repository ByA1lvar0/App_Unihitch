-- Convertir columna dominio a array de texto
ALTER TABLE universidad ALTER COLUMN dominio TYPE TEXT[] USING string_to_array(dominio, ',');

-- Actualizar UCV con ambos dominios
UPDATE universidad 
SET dominio = ARRAY['ucv.edu.pe', 'ucvvirtual.edu.pe'] 
WHERE nombre LIKE '%Universidad César Vallejo%';

-- Actualizar UNP con ambos dominios
UPDATE universidad 
SET dominio = ARRAY['unp.edu.pe', 'alumnos.unp.edu.pe'] 
WHERE nombre LIKE '%Universidad Nacional de Piura%';

-- Asegurar que los demás sean arrays válidos (aunque la conversión lo hace, reforzamos)
UPDATE universidad SET dominio = ARRAY['udep.edu.pe'] WHERE nombre LIKE '%Universidad de Piura%';
UPDATE universidad SET dominio = ARRAY['upn.edu.pe'] WHERE nombre LIKE '%Universidad Privada del Norte%';
UPDATE universidad SET dominio = ARRAY['usmp.pe'] WHERE nombre LIKE '%Universidad de San Martín de Porres%';
UPDATE universidad SET dominio = ARRAY['utp.edu.pe'] WHERE nombre LIKE '%Universidad Tecnológica del Perú%';
