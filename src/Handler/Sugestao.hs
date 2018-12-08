{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE QuasiQuotes #-}
module Handler.Sugestao where

import Text.Lucius
import Text.Julius
import Import
import Prelude (read)
import Database.Persist.Sql

widgetBootstrapLinks :: Widget
widgetBootstrapLinks = $(whamletFile "templates/bootstrapLinks.hamlet")

formSugestao :: PlayerId -> Form Sugestao
formSugestao plaid = renderBootstrap $ Sugestao plaid
    <$> areq textField "Nome: " Nothing
    <*> aopt textField "Ação Ativa: " Nothing
    <*> aopt textField "Ação Passiva: " Nothing
    
getSugestaoR :: PlayerId -> Handler Html
getSugestaoR plaid = do
    -- GERA O FORMULARIO NA widgetForm
    player <- runDB $ get404 plaid
    (widgetForm, enctype) <- generateFormPost (formSugestao plaid)
    defaultLayout $ do
        addStylesheetRemote "https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css"
        toWidget $(luciusFile "templates/sugestao.lucius")
        $(whamletFile "templates/sugestao.hamlet")
    
postSugestaoR :: PlayerId -> Handler Html
postSugestaoR plaid = do
    -- LE O DIGITADO
    ((res,_),_) <- runFormPost (formSugestao plaid)
    case res of
        FormSuccess sugestao -> do
            -- INSERE O PRODUTO
            iid <- runDB $ insert sugestao
            setMessage [shamlet|
                Sugestão enviada com sucesso!
            |]
            redirect HomeR
        _ -> redirect HomeR
        
getPainelR :: Handler Html
getPainelR = do
    admin <- lookupSession "_ADM"
    case admin of
        Just _ -> do 
            defaultLayout $ do 
                addStylesheetRemote "https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css"
                toWidget $(luciusFile "templates/painelSugestaoAdm.lucius")
                $(whamletFile "templates/painelSugestaoAdm.hamlet")
        Nothing -> do
            logado <- lookupSession "_PLA"
            case logado of 
                Just sessionPlayer -> do 
                    dados <- return $ read $ unpack sessionPlayer
                    player <- runDB $ selectFirst [PlayerEmail ==. (playerEmail dados), PlayerSenha ==. (playerSenha dados)] []
                    case player of
                        Just (Entity plaid _) -> do
                            pid <- return $ plaid
                            defaultLayout $ do 
                                addStylesheetRemote "https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css"
                                toWidget $(luciusFile "templates/painelSugestaoLogado.lucius")
                                $(whamletFile "templates/painelSugestaoLogado.hamlet")
                        Nothing -> do
                            defaultLayout $ do 
                                addStylesheetRemote "https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css"
                                toWidget $(luciusFile "templates/painelSugestao.lucius")
                                $(whamletFile "templates/painelSugestao.hamlet")
                Nothing -> do
                    defaultLayout $ do 
                        addStylesheetRemote "https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css"
                        toWidget $(luciusFile "templates/painelSugestao.lucius")
                        $(whamletFile "templates/painelSugestao.hamlet")