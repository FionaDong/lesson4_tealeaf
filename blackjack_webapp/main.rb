require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_MAX = 21
DEALER_MIN_HIT = 17
PLAYER_TOTAL_AMOUNT = 500

helpers do
  def convert_image(card, cover=false)
    suit = case card[1]
            when 'd'
              'diamonds'      
            when 'h'
              'hearts'
            when 'c'
              'clubs'
            when 's'
              'spades' 
            end
    value = case card[0]
    when 'A'
      'ace'
    when 'J'
      'jack'
    when 'K'
      'king'
    when 'Q'
      'queen'
    else
      card[0]
    end

   return "<img src='/images/cards/#{suit}_#{value}.jpg'>"

  end

  def calculate(cards)
    value = 0
    cards.each do |card|
      value += case card[0]
               when 'A'
                 11
               when 'J' 
                 10
               when 'Q'
                 10
               when 'K'
                 10
               else
                 card[0]
               end
              end
    if value > BLACKJACK_MAX
      ace_cards = cards.select{|card| card[0] == 'A'}
      if ace_cards.empty?
        return value
      else
        until ace_cards.empty?
        ace_cards.pop
        value -= 10
        return value if value <= BLACKJACK_MAX
        end
      end
    end
    return value
  end

  def bet_validate_true?(bet)
    return bet.to_i > 0 && bet.to_i <= session[:total_amount]
  end


  def busted?(cards)
    if calculate(cards) > BLACKJACK_MAX
      @dealer_show_hands = true  
    end
    return calculate(cards) > BLACKJACK_MAX
  end 

  def hit_BJ?(cards)
    if calculate(cards) == BLACKJACK_MAX
      @dealer_show_hands = true
    end    
    return calculate(cards) == BLACKJACK_MAX
  end


  def dealer_turn
    if busted?(session[:dealer_cards])
      session[:total_amount] += session[:bet]
      @message = 'Congrats, dealer busted, you win.'
      return
    elsif hit_BJ?(session[:dealer_cards])
      session[:total_amount] -= session[:bet]
      @message = 'Sorry, dealer hit blackjack.'
      return
    elsif calculate(session[:dealer_cards]) < DEALER_MIN_HIT
      session[:dealer_cards] << session[:cards].pop
      dealer_turn
    end
  end


  def who_is_winner
    return if @dealer_show_hands
    if calculate(session[:player_cards]) >= calculate(session[:dealer_cards])
      session[:total_amount] += session[:bet]
      @message = 'Congrats, you win!'
      @dealer_show_hands = true
    elsif calculate(session[:player_cards]) < calculate(session[:dealer_cards])
      session[:total_amount] -= session[:bet]
      @message = 'Sorry, you lost it~'
      @dealer_show_hands = true     
    end
  end

  def player_check_hands
    if busted?(session[:player_cards])
      session[:total_amount] -= session[:bet]
      @message = 'Sorry, you busted.'
    elsif hit_BJ?(session[:player_cards])
      session[:total_amount] += session[:bet]
      @message = 'Congrats, you win, you hit the blackjack.'
    end    
  end
end

before do
  @dealer_show_hands = false
end

get '/' do
  if !session[:player_name]
    redirect '/set_player_name'
  else
    "Hello World, welcome back again."
    redirect '/game'
  end
end

get '/new_game' do
  session.clear
  redirect '/'
end

get '/set_player_name' do
  erb :set_player_name
end

post '/new_player' do
  session[:player_name] = params[:player_name]
  session[:player_name].strip!
  if session[:player_name].length == 0
    @message = "Please tell me your name ~"
    halt erb(:set_player_name)
  else
    redirect '/bet'
  end
end

get '/bet' do
  session[:total_amount] = PLAYER_TOTAL_AMOUNT if session[:total_amount].nil?
  redirect '/game_over' if session[:total_amount] == 0
  
  erb :set_bet
end

post '/bet_done' do
  if !bet_validate_true?(params[:bet])
    @message = 'this bet is not available.'
    halt erb(:set_bet)
  end
  session[:bet] = params[:bet].to_i
  redirect '/game'
end

get '/game_over' do
  if session[:total_amount] == 0
    @message = 'You have run out of money~'
  else 
    @message = "You have finally amassed $ #{session[:total_amount]}."
  end
  erb :game_over
end

get '/game' do
  session[:cards] = ['A', 2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K'].product(['c', 's', 'h', 'd']).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_cards] << session[:cards].pop
  session[:dealer_cards] << session[:cards].pop
  session[:player_cards] << session[:cards].pop
  session[:dealer_cards] << session[:cards].pop
  player_check_hands
  erb :show_cards
end

post '/player_hit' do
  session[:player_cards] << session[:cards].pop
  player_check_hands
  erb :show_cards,layout: false
end

post '/player_stay' do
  dealer_turn
  who_is_winner
  erb :show_cards, layout: false
end


