# app/controllers/certificates_controller.rb
require "zip"

class CertificatesController < ApplicationController
  def new
    # Esta acción solo muestra el formulario de subida.
  end

  def create
    excel_file = params[:excel_file]
    word_template = params[:word_template]

    if excel_file.nil? || word_template.nil?
      redirect_to root_path, alert: "Por favor sube ambos archivos."
      return
    end

    # Creamos un archivo ZIP temporal en el servidor
    temp_zip_file = Tempfile.new([ "certificados", ".zip" ])

    begin
      # Leemos el archivo Excel subido
      excel = Roo::Excelx.new(excel_file.path)
      template_path = word_template.path

      # Abrimos el archivo ZIP para empezar a llenarlo
      Zip::File.open(temp_zip_file.path, create: true) do |zipfile|
        # Leemos el Excel y procesamos cada fila que tenga datos
        excel.sheet(0).parse(header_search: []).each_with_index do |row, index|
          # Esta línea ignora las filas vacías al final del Excel
          next if row["FOLIO"].blank?

          # Creamos el hash 'contexto' con los datos de la fila actual del Excel.
          # Las claves (ej. :folio) deben coincidir con los nombres de los MergeFields en el Word.
          context = {
            folio:           row["FOLIO"],
            factura:         row["FACTURA"],
            id_cliente:      row["ID CLIENTE"],
            nombre_generador: row["GENERADOR"],
            id_generador:     row["NUMERO IDENTIFICACION"],
            cantidad:         row["CANT."].to_s,
            fecha_recepcion:  row["FECHA ENTREGA"],
            nombre_gestor:    row["GESTOR O TRANSPORTADOR"],
            id_gestor:        row["NUMERO IDENTIFICACION"],
            procedencia:      row["TIPO RESIDUO"],
            direccion:        row["DIRECCION DEL RESIDUO"],
            fecha_actual:     Time.zone.now.strftime("%d-%m-%Y")
          }

          # Cargamos la plantilla de Word
          template = Sablon.template(template_path)
          # Renderizamos la plantilla, reemplazando los «MergeFields» con los datos del contexto
          generated_document = template.render_to_string(context)

          # Creamos un nombre de archivo único para el documento generado
          internal_filename = "#{row["FOLIO"]}-#{row["GENERADOR"].to_s.parameterize}.docx"

          # Añadimos el documento generado al ZIP
          zipfile.get_output_stream(internal_filename) { |f| f.write generated_document }
        end
      end

      # Leemos el ZIP ya completo para enviarlo al usuario
      zip_data = File.read(temp_zip_file.path)

      # Enviamos el archivo ZIP para que el usuario lo descargue
      send_data zip_data,
                filename: "certificados_generados_#{Date.today.strftime('%Y%m%d')}.zip",
                type: "application/zip",
                disposition: "attachment"

    ensure
      # Borramos el archivo ZIP temporal del servidor para no dejar basura
      temp_zip_file.close
      temp_zip_file.unlink
    end
  end
end
