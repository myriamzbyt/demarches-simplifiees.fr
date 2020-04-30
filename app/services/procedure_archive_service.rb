require 'tempfile'

class ProcedureArchiveService
  def initialize(procedure)
    @procedure = procedure
  end

  def create_archive(instructeur, type, month = nil)
    if type == 'everything'
      dossiers = @procedure.dossiers.state_termine
      filename = "procedure-#{@procedure.id}.zip"
    else
      dossiers = @procedure.dossiers.termine_durant(month)
      filename = "procedure-#{@procedure.id}-mois-#{I18n.l(month, format: '%Y-%m')}.zip"
    end
    files = create_list_of_attachments(dossiers)

    archive = Archive.create(
      content_type: type,
      month: month,
      procedure: @procedure,
      instructeur: instructeur
    )
    tmp_file = Tempfile.new(['tc', '.zip'])

    Zip::OutputStream.open(tmp_file) do |zipfile|
      # Les pièces justificatives
      files.each do |attachment, pj_filename|
        zipfile.put_next_entry(pj_filename)
        zipfile.puts(attachment.download)
      end

      # L'export PDF des dossier
      dossiers.each do |dossier|
        zipfile.put_next_entry("dossier-#{dossier.id}/dossier-#{dossier.id}.pdf")
        zipfile.puts(ApplicationController.render(template: 'dossiers/show',
                        formats: [:pdf],
                        assigns: {
                          include_infos_administration: false,
                          dossier: dossier
                        }))
      end
    end

    archive.file.attach(io: File.open(tmp_file), filename: filename)
    tmp_file.delete
    archive.make_available!
    InstructeurMailer.send_archive(instructeur, archive).deliver_now
  end

  def self.poids_total_procedure(procedure)
    raw_select = <<-SQL
    select
      sum(bl.byte_size) as poids_total
    from
      active_storage_attachments asa
      left join active_storage_blobs bl on bl.id = asa.blob_id
      left join champs c on c.id = asa.record_id
      left join types_de_champ tdc on tdc.id = c.type_de_champ_id
      left join procedures p on p.id = tdc.procedure_id
    where
      p.id = #{procedure.id};
    SQL

    pg = ActiveRecord::Base.connection.execute(raw_select)

    pg.first['poids_total'].to_i
  end

  def self.poids_total_dossiers(dossiers)
    return 0 if dossiers.empty?

    ids = dossiers.pluck(:id).join(',')

    raw_select = <<-SQL
    select
      sum(bl.byte_size) as poids_total
    from
      active_storage_attachments asa
      left join active_storage_blobs bl on bl.id = asa.blob_id
      left join champs c on c.id = asa.record_id
      left join types_de_champ tdc on tdc.id = c.type_de_champ_id
      left join procedures p on p.id = tdc.procedure_id
    where
      c.dossier_id in (#{ids});
    SQL

    pg = ActiveRecord::Base.connection.execute(raw_select)

    pg.first['poids_total']
  end

  def create_list_of_attachments(dossiers)
    dossiers.flat_map do |dossier|
      ActiveStorage::DownloadableFile.create_attachment_list_from_dossier(dossier)
    end
  end

  private

  def dossier_pdf_link(dossier)
    Rails.application.routes.url_helpers.instructeur_dossier_url(@procedure, dossier, format: :pdf)
  end

  def empty_procedure_pdf_link
    if @procedure.brouillon?
      Rails.application.routes.url_helpers.commencer_dossier_vide_test_url(path: @procedure.path, format: :pdf)
    else
      Rails.application.routes.url_helpers.commencer_dossier_vide_url(path: @procedure.path, format: :pdf)
    end
  end
end
