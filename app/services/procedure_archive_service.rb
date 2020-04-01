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

  def self.poids_total(dossiers)
    dossiers.map do |dossier|
      PiecesJustificativesService.liste_pieces_justificatives(dossier).sum(&:byte_size)
    end.sum
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
