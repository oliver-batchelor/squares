module States where


import Dict exposing (Dict)

import Maybe
import Maybe exposing (andThen)

import Port exposing (Message)
import Debug exposing (log)


type alias UserName = String
type alias UserId = Int
  
type alias PlayingState = 
  { id : UserId
  , users :  Users
  , log : List ChatLog
  , chat : String
  }
  

type alias LoginState = 
  { error : Maybe String
  , waiting : Bool
  , login   : String
  }
  
  
type Model = NotConnected | Login LoginState  | Playing PlayingState


type alias Users = Dict UserId UserName
type alias ChatLog = {sender : UserName, message : String, status : Maybe Bool}
  
type ClientMessage = ClientChat String | ClientLogin String | ClientHello


type ServerMessage 
    = UserConnected Int String
    | UserDisconnected Int
    | Chat Int String
    | Error String
    | Welcome Int Users
    | Connected
    

type Action 
  = ServerMessage ServerMessage
  | UpdateChat String
  | SubmitChat 
  | UpdateLogin String
  | SubmitLogin 


type alias SendAction = Action -> Port.Message


  
update : Action -> (Model, Maybe ClientMessage) -> (Model, Maybe ClientMessage)
update action (model, _) = Debug.log (toString action) (case model of
  Playing p -> updatePlaying action p
  Login l   -> updateLogin action l
  NotConnected -> waitConnection action)


  
no : a -> (a, Maybe b)
no a = (a, Nothing)

out : a -> b -> (a, Maybe b)
out a b = (a, Just b)

waitConnection : Action -> (Model, Maybe ClientMessage)
waitConnection action  = case action of
  ServerMessage message -> case message of 
    Connected -> out login ClientHello
    _         -> no NotConnected
  _         -> no NotConnected



updateLogin : Action -> LoginState -> (Model, Maybe ClientMessage)
updateLogin action l = case action of
  ServerMessage message -> case message of 
    Welcome id users -> no (playing id)
    _          -> no (Login l)
    
  UpdateLogin login   -> no (Login  {l | login   <- login})
  SubmitLogin         -> out (Login {l | waiting <- True}) (ClientLogin l.login) 
  
  _  -> no (Login l)

                           

noP : PlayingState -> (Model, Maybe ClientMessage)
noP p = (Playing p, Nothing)

updatePlaying : Action -> PlayingState -> (Model, Maybe ClientMessage)
updatePlaying action p =  case action of
  ServerMessage message -> (serverMessage message p, Nothing)
  SubmitChat           -> out (Playing {p | chat <- ""}) (ClientChat p.chat)
  UpdateChat msg       -> noP {p | chat <- msg}
  _                    -> noP p


serverMessage : ServerMessage -> PlayingState  -> Model
serverMessage message p =  case message of
    UserConnected id name  -> Playing p
    UserDisconnected id    -> Playing p
    Chat id message      -> Playing p
    Error reason         -> Playing p
    _ -> Playing p
       

initial : Model
initial = NotConnected
     
     
login : Model
login = Login 
  { error = Nothing
  , waiting = False
  , login = ""
  }
  
playing : Int -> Model
playing id = Playing
  { id = id
  , users = Dict.empty
  , log = []
  , chat = ""
  }
