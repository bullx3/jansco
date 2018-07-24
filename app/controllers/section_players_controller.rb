class SectionPlayersController < AdminController
  before_action :set_section_player, only: [:show, :edit, :update, :destroy]

  # GET /section_players
  # GET /section_players.json
  def index
    @section_players = SectionPlayer.all
  end

  # GET /section_players/1
  # GET /section_players/1.json
  def show
  end

  # GET /section_players/new
  def new
    @section_player = SectionPlayer.new
  end

  # GET /section_players/1/edit
  def edit
  end

  # POST /section_players
  # POST /section_players.json
  def create
    @section_player = SectionPlayer.new(section_player_params)

    respond_to do |format|
      if @section_player.save
        format.html { redirect_to @section_player, notice: 'Section player was successfully created.' }
        format.json { render :show, status: :created, location: @section_player }
      else
        format.html { render :new }
        format.json { render json: @section_player.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /section_players/1
  # PATCH/PUT /section_players/1.json
  def update
    respond_to do |format|
      if @section_player.update(section_player_params)
        format.html { redirect_to @section_player, notice: 'Section player was successfully updated.' }
        format.json { render :show, status: :ok, location: @section_player }
      else
        format.html { render :edit }
        format.json { render json: @section_player.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /section_players/1
  # DELETE /section_players/1.json
  def destroy
    @section_player.destroy
    respond_to do |format|
      format.html { redirect_to section_players_url, notice: 'Section player was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_section_player
      @section_player = SectionPlayer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def section_player_params
      params.require(:section_player).permit(:section_id, :player_id, :total, :paid)
    end
end
