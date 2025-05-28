# frozen_string_literal: true

# Controller for survey responses

# rubocop:disable Metrics/ClassLength
class SurveyResponsesController < ApplicationController
  include Pagination
  helper_method :invite_token

  before_action :set_survey_data, only: %i[show edit update destroy]
  before_action :set_survey_sections, only: %i[show edit update survey new]

  # GET /survey_responses or /survey_responses.json
  def index
    if params[:query].present?

      @survey_responses = Invitation.where(token: params[:query]).map(&:response)
      flash[:warning] = "No survey responses found for share code #{params[:query]}" if @survey_responses.empty?
    else
      @survey_responses = SurveyResponse.all
    end
  end

  # GET /survey_responses/1 or /survey_responses/1.json
  def show
    return return_to_root 'You are not logged in.' if current_user_id.nil?
  
    return return_to_root 'You cannot view this result.' if !user_is_admin? && (current_user_id != @survey_response&.profile&.user_id)
  
    set_survey_sections # Ensure sections are correctly set
  
    invited_survey = InvitationClaim.exists?(survey_response_id: @survey_response.id)
  
    flash.keep(:warning)
  
    respond_to do |format|
      if invited_survey
        format.html { render 'survey_responses/show_invitation' }
        format.xlsx do
          response.headers['Content-Disposition'] = "attachment; filename=OLEI_Survey_#{@survey_response.id}.xlsx"
        end
      else
        format.html { render 'survey_responses/show' }
        format.xlsx do
          response.headers['Content-Disposition'] = "attachment; filename=Self_Assessment_#{@survey_response.id}.xlsx"
        end
      end
    end
  end
  
  def current_user_id
    session[:userinfo]['sub'] if session.dig(:userinfo, 'sub').present? && !session[:userinfo]['sub'].nil?
  end

  def new
    # login check is done in secure.rb
    logger.info '========== new triggered =========='

    @pagination, @questions, @section = paginate(collection: SurveyQuestion.all, params: { per_page: 10, page: 1 })
    @survey_response = SurveyResponse.new
    return return_to_root 'You are not logged in.' if current_user_id.nil?
    return return_to_root 'Your profile could not be found. Please complete your profile.' unless SurveyProfile.exists?(user_id: current_user_id)

    @survey_profile = SurveyProfile.find_by(user_id: current_user_id)

    session[:survey_id] = nil
    session[:page_number] = 1
  end

  # GET /survey/page/:page
  def survey
    logger.info '========== survey triggered =========='
    @pagination, @questions, @section = paginate(collection: SurveyQuestion.all, params: { per_page: 10, page: params[:page] })
    @survey_response = SurveyResponse.find_by_id(session[:survey_id])
    render :survey
  end

  # GET /survey_responses/1/edit
  def edit
    logger.info '========== edit triggered =========='
    return return_to_root 'You are not logged in.' if current_user_id.nil?
    return return_to_root 'Your profile could not be found. Please complete your profile.' unless SurveyProfile.exists?(user_id: current_user_id)
    return return_to_root 'You cannot edit this result.' if current_user_id != @survey_response.profile.user_id

    # Initialize page number to 1 if not already set
    session[:page_number] = 1 if session[:page_number].nil?

    @pagination, @questions, @section = paginate(collection: SurveyQuestion.all, params: { per_page: 10, page: session[:page_number] })
  end

  # POST /survey_responses or /survey_responses.json
  # rubocop:disable all
  def create
    logger.info '========== create triggered =========='
    return respond_with_error 'invalid_form' if invalid_form?
    return return_to_root 'You are not logged in.' if current_user_id.nil?
    return return_to_root 'Your profile could not be found. Please complete your profile.' unless SurveyProfile.exists?(user_id: current_user_id)

    if session[:survey_id].present?
      @survey_response = SurveyResponse.find_by(id: session[:survey_id])
      @survey_response.add_from_params current_user_id, survey_response_params
    else
      @survey_response = SurveyResponse.create_from_params current_user_id, survey_response_params
      session[:survey_id] = @survey_response.id
    end

    case params[:commit]
    when 'Next ➡'
      session[:page_number] ||= 1
      session[:page_number] += 1
      redirect_to edit_survey_response_path(@survey_response)
    when '⬅ Previous'
      session[:page_number] ||= 1
      session[:page_number] = [session[:page_number] - 1, 1].max
      redirect_to edit_survey_response_path(@survey_response)
    else # Final Submit
      session[:page_number] = nil
      session[:survey_id] = nil
      redirect_to survey_response_path(@survey_response), notice: 'Survey response was successfully submitted.'
    end
  end

  def get_answer(response, question_id)
    answer = response.answers.find_by(question_id: question_id)
    answer&.choice
  end
  
  def get_supervisee_average(question_id)
    # Assuming you have logic to calculate the average of supervisees' answers for a given question.
    supervisees_responses = SuperviseeResponse.where(question_id: question_id)
    supervisees_responses.average(:choice).round if supervisees_responses.exists?
  end

  # PATCH/PUT /survey_responses/1 or /survey_responses/1.json
  def update
    logger.info '========== update triggered =========='
    return respond_with_error 'invalid form' if invalid_form?
    return return_to_root 'You are not logged in.' if current_user_id.nil?
    return return_to_root 'Your profile could not be found. Please complete your profile.' unless SurveyProfile.exists?(user_id: current_user_id)
    return return_to_root 'You cannot update this result.' if current_user_id != @survey_response.profile.user_id

    unless survey_response_params.nil?
      @survey_response.add_from_params current_user_id, survey_response_params
    end

    respond_to do |format|
      if params[:commit] == 'Next ➡'
        session[:page_number] ||= 1
        session[:page_number] += 1
        format.html { redirect_to edit_survey_response_path(@survey_response) }
      elsif params[:commit] == '⬅ Previous'
        session[:page_number] ||= 1
        session[:page_number] = [session[:page_number] - 1, 1].max
        format.html { redirect_to edit_survey_response_path(@survey_response) }
      else
        session[:page_number] = nil
        session[:survey_id] = nil
        format.html { redirect_to survey_response_path(@survey_response), notice: 'Survey response was successfully submitted.' }
        format.json { render :show, status: :ok, location: @survey_response }
      end
    end
  end
  # rubocop:enable all

  # DELETE /survey_responses/1 or /survey_responses/1.json
  def destroy
    ActiveRecord::Base.transaction do
      Rails.logger.info "Starting deletion of SurveyResponse ID: #{@survey_response.id}"
  
      # 1. Find the invitation claims associated with this response
      invitation_claims_deleted = InvitationClaim.where(survey_response_id: @survey_response.id).destroy_all
      Rails.logger.info "Deleted #{invitation_claims_deleted.count} invitation claims for SurveyResponse ID: #{@survey_response.id}"
  
      # 2. Check if this survey response was created via an invitation
      associated_invitation = Invitation.find_by(response_id: @survey_response.id)
  
      # If this was an invitee's response, remove only their reference, NOT the invitation itself
      associated_invitation.update(response_id: nil) if associated_invitation
  
      # 3. Delete all answers associated with this response
      survey_answers_deleted = SurveyAnswer.where(response_id: @survey_response.id).destroy_all
      Rails.logger.info "Deleted #{survey_answers_deleted.count} survey answers for SurveyResponse ID: #{@survey_response.id}"
  
      # 4. Finally, delete the survey response itself
      if @survey_response.destroy!
        Rails.logger.info "Successfully deleted SurveyResponse ID: #{@survey_response.id}"
      else
        Rails.logger.warn "Failed to delete SurveyResponse ID: #{@survey_response.id}"
      end
    end
  
    respond_to do |format|
      if user_is_admin?
        format.html { redirect_to admin_dashboard_path, notice: 'Survey response was successfully destroyed.' }
      else
        format.html { redirect_to root_path, notice: 'Survey response was successfully destroyed.' }
      end
      format.json { head :no_content }
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    Rails.logger.error "Failed to delete SurveyResponse: #{e.message}"
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: "Failed to destroy survey response: #{e.message}" }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end  

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_survey_data
    logger.info '========== set_survey_data triggered =========='
    @survey_response = SurveyResponse.find_by(id: params[:id])
    if @survey_response.nil?
      flash[:alert] = 'Survey not found'
      redirect_to root_path
    else
      @questions = @survey_response.questions
    end
  end  

  # rubocop:disable Metrics/MethodLength
  def set_survey_sections
    logger.info '========== set_survey_sections triggered =========='
  
    return return_to_root('You are not logged in.') if current_user_id.nil?
    return return_to_root('Your profile could not be found. Please complete your profile.') unless SurveyProfile.exists?(user_id: current_user_id)
  
    @survey_profile = SurveyProfile.find_by(user_id: current_user_id)
  
    # Default prompts for self-assessment
    default_prompts = [
      {
        title: 'Part 1: Leadership Behavior - Management',
        prompt: 'To what extent do you agree that the following behaviors reflect your personal leadership approach?'
      },
      {
        title: 'Part 1: Leadership Behavior - Interpersonal',
        prompt: 'To what extent do you agree that the following behaviors reflect your interpersonal leadership style?'
      },
      {
        title: 'Part 2. External Forces',
        prompt: 'To what extent do you believe these external factors influence your leadership?'
      },
      {
        title: 'Part 3. Organizational Structure',
        prompt: 'To what extent do you agree that the following characteristics describe your organization’s structure?'
      },
      {
        title: 'Part 4. Values, Attitudes, and Beliefs',
        prompt: 'To what extent do you agree that the following characteristics represent your perspectives?'
      },
      {
        title: 'Part 4. Values, Attitudes, and Beliefs',
        prompt: 'To what extent do you agree that the following characteristics apply to your external community (e.g., leadership, management, stakeholders)?'
      }
    ]
  
    # If there's no @survey_response yet (e.g., on the "new" page), just return defaults
    if @survey_response.nil?
      @sections = default_prompts
      return
    end
  
    # Check if this survey response came from an invitation
    invitation_claim = InvitationClaim.find_by(survey_response_id: @survey_response.id)
    if invitation_claim
      inviter_profile = invitation_claim.invitation.parent_response.profile
      first_name = inviter_profile.first_name.presence
      last_name = inviter_profile.last_name.presence
      full_name = [first_name, last_name].compact.join(' ')
      inviter_name = full_name.blank? ? 'the leader' : full_name
  
      @sections = [
        {
          title: 'Part 1: Leadership Behavior - Management',
          prompt: "To what extent do you agree that the following behaviors reflect the leadership approach of #{inviter_name}?"
        },
        {
          title: 'Part 1: Leadership Behavior - Interpersonal',
          prompt: "To what extent do you agree that the following behaviors reflect the interpersonal leadership style of #{inviter_name}?"
        },
        {
          title: 'Part 2. External Forces',
          prompt: "To what extent do you believe these external factors influence the leadership of #{inviter_name}?"
        },
        {
          title: 'Part 3. Organizational Structure',
          prompt: "To what extent do you agree that the following characteristics describe the organization’s structure from the perspective of #{inviter_name}?"
        },
        {
          title: 'Part 4. Values, Attitudes, and Beliefs',
          prompt: "To what extent do you agree that the following characteristics represent the perspectives of #{inviter_name}?"
        },
        {
          title: 'Part 4. Values, Attitudes, and Beliefs',
          prompt: "To what extent do you agree that the following characteristics apply to the external community of #{inviter_name} (e.g., leadership, management, stakeholders)?"
        }
      ]
    else
      @sections = default_prompts
    end
  end
  
  # rubocop:enable Metrics/MethodLength
  def invalid_form?
    return false if survey_response_params.nil?

    survey_response_params.values.any? { |value| value.nil? || value.empty? }
  end

  def respond_with_error(message, status = :unprocessable_entity)
    respond_to do |format|
      format.html do
        redirect_to new_survey_response_path, notice: message, status:
      end
      format.json { render json: { error: message }, status: }
    end
  end

  def return_to_root(message)
    respond_to do |format|
      format.html do
        redirect_to root_url, notice: message
      end
      format.json { render json: { error: message }, status: }
    end
  end

  def survey_response_params
    return unless params.include? :survey_response

    params.require(:survey_response).permit!
  end

  def invite_token(response)
    invitation = Invitation.find_by(response_id: response.id)
    invitation ? invitation.token : 'N/A'
  end
end
