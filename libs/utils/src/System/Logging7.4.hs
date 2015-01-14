{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE OverlappingInstances #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE ViewPatterns #-}

{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

import Prelude hiding (log, lookup)
--import Data.String.Class (ToString(toString))
import qualified Control.Monad.State as State
import           Control.Monad.State (StateT, runStateT)
import           Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Applicative hiding (empty)
import Data.Generics (Generic)
import Data.Monoid
import Control.Monad.Identity (Identity, runIdentity)
import Data.Sequence (Seq, (|>))
import qualified Data.Text.Lazy as Text
import Data.Text.Lazy (Text)
import Control.Lens hiding ((|>), children, LevelData, Level)
import Control.Monad (when)
import Control.Monad.Trans (MonadTrans, lift)
import Data.Foldable (toList)

import Data.Time (getCurrentTime)
import Data.Typeable
import System.IO (stdout)
import Text.PrettyPrint.ANSI.Leijen hiding ((<>), (<$>), empty)
import Control.Concurrent (threadDelay)
import           Control.Monad.Reader (ReaderT, runReaderT)
import qualified Control.Monad.Reader as Reader
import           Control.Concurrent.Chan.Unagi (readChan, writeChan, newChan, InChan, OutChan)
import           Control.Concurrent (forkIO)

import System.Log.Level


newtype Log a = Log { unLog :: a } deriving (Show, Functor) -- { _msg      :: a 
                         --, _logPath  :: [Text]
                         --, _priority :: Int
                         --, _threadID :: Int
                         --, _procID   :: Int
                         --, _time     :: Int
                         -- } deriving (Show)




--data Segment = Msg
--             | Name
--             | Priority
--             | ThreadID
--             | ProcessID
--             -- | Time -- <timeFormatter>
--             deriving (Show)

-- dorobic IsString do Segmentu

class DataGetter base m where
    getData :: m (Data base)





data Time = Time deriving (Show)
type instance DataOf Time = Int

instance MonadIO m => DataGetter Time m where
    getData = do liftIO $ print "reading time"
                 liftIO $ threadDelay 1000000
                 return $ Data Time 5



--class LogFilter where
--    filterLog :: (a ->)



data Msg = Msg deriving (Show)
type instance DataOf Msg = String


--data Msg2 a = Msg2 a deriving (Show)
--type instance DataOf (Msg2 a) = a


data LevelData = LevelData Int String deriving (Show, Ord, Eq)

mkLevel a = LevelData (fromEnum a) (show a)

data Lvl = Lvl deriving (Show)
type instance DataOf Lvl = LevelData


data Data base = Data { recBase :: base
                      , recData :: DataOf base
                      }

deriving instance (Show (DataOf base), Show base) => Show (Data base)

type family DataOf a :: *

--data DataProvider base d = 


type family LogFormat (m :: * -> *)

----------------------------------------------------------------------
-- Formatters
----------------------------------------------------------------------

newtype Formatter a = Formatter { runFormatter :: Log a -> Doc }

instance Show (Formatter a) where
    show _ = "Formatter"

--read log = readData

--foo = Formatter $ show . readData Msg

foo = colorLvlFormatter ("[" <:> Lvl <:> "] ") <:> Msg <:> " !"

colorLvlFormatter f = Formatter (\s -> let (LevelData pr _) = readData Lvl s in lvlColor pr $ runFormatter f s)

lvlColor lvl
    | lvl == 0  = id
    | lvl <= 2  = green
    | lvl == 3  = yellow
    | otherwise = red



mapFormatter f (Formatter a) = Formatter (f a)

(<:>) :: (FormatterBuilder a c, FormatterBuilder b c) => a -> b -> Formatter c
(<:>) a b = concatFormatters (buildFormatter a) (buildFormatter b)

concatFormatters :: Formatter a -> Formatter a -> Formatter a
concatFormatters (Formatter f) (Formatter g) = Formatter (\s -> f s <> g s)

class FormatterBuilder a b where
    buildFormatter :: a -> Formatter b

instance FormatterBuilder String a where
    buildFormatter a = Formatter $ const (text a)

instance FormatterBuilder Doc a where
    buildFormatter a = Formatter $ const a

--instance Lookup Lvl a => FormatterBuilder Lvl (Formatter a) where
--    buildFormatter a = Formatter $ pprint . readData a

instance (PPrint (DataOf seg), Lookup seg (Log a)) => FormatterBuilder seg a where
    buildFormatter a = Formatter $ pprint . readData a

instance (a~b) => FormatterBuilder (Formatter a) b where
    buildFormatter = id

class PPrint a where
    pprint :: a -> Doc

instance PPrint String where
    pprint = text

instance Pretty a => PPrint a where
    pprint = pretty

instance Pretty LevelData where
    pretty (LevelData _ name) = text name

--class FormatterBuilder a b c where
--    buildFormatter :: a -> b -> c

--instance FormatterBuilder String String (Formatter a) where
--    buildFormatter a b = Formatter (const a) `buildFormatter` Formatter (const b)

--instance (a~b, a~c) => FormatterBuilder (Formatter a) (Formatter b) (Formatter c) where
--    buildFormatter (Formatter f) (Formatter g) = Formatter (\s -> f s <> g s)

--instance Lookup a l => FormatterBuilder String a b where
--    buildFormatter s a = Formatter (const s) `buildFormatter` Formatter (show . readData a)

----------------------------------------------------------------------
-- Data reading
----------------------------------------------------------------------

class LookupDataSet base s where 
    lookupDataSet :: base -> s -> Data base

instance LookupDataSet base (Data base,as) where
    lookupDataSet _ (a,_) = a

instance LookupDataSet base as => LookupDataSet base (Data b,as) where
    lookupDataSet b (_, as) = lookupDataSet b as



class Lookup base s where 
    lookup :: base -> s -> Data base

instance LookupDataSet base l => Lookup base (Log l) where
    lookup b (unLog -> s) = lookupDataSet b s

instance LookupDataSet base r => Lookup base (RecordBuilder r) where
    lookup b (fromRecordBuilder -> r) = lookupDataSet b r

--instance Lookup base (Log as) => Lookup base (Log (Data b,as)) where
--    lookup b (unLog -> (_, as)) = lookup b (Log as)


--instance Lookup base as => Lookup base (Data b,as) where
--    lookup b (_, as) = lookup b as

readData :: Lookup a l => a -> l -> DataOf a
readData a = recData . lookup a

--readData' :: (Lookup a r) => a -> Log l -> DataOf a
--readData' a = readData a

----------------------------------------------------------------------
-- RecordBuilder
----------------------------------------------------------------------

newtype RecordBuilder a = RecordBuilder { fromRecordBuilder :: a } deriving (Show, Functor)
empty = RecordBuilder ()

appData :: (a~DataOf base) => base -> a -> RecordBuilder as -> RecordBuilder (Data base, as)
appData base a = fmap (Data base a,)


----------------------------------------------------------------------
-- MonadLogger
----------------------------------------------------------------------

class (Monad m, Applicative m) => MonadLogger m where
    appendLog :: Log (LogFormat m) -> m ()
    flush     :: m ()
    close     :: m ()

    default flush :: m ()
    flush = return ()

    default close :: m ()
    close = return ()

instance (MonadTrans t, MonadLogger m, LogFormat (t m) ~ LogFormat m, Applicative m, Applicative (t m), Monad(t m)) 
      => MonadLogger (t m) where
    appendLog = lift . appendLog



class MonadLogger m => MonadLoggerHandler h m | m -> h where
    addHandler :: h -> m ()
    -- ... ?

instance (MonadTrans t, MonadLoggerHandler h m, MonadLogger (t m)) => MonadLoggerHandler h (t m) where
    addHandler = lift . addHandler


----------------------------------------------------------------------
-- LogBuilder
----------------------------------------------------------------------


class LogBuilder a m b where
    buildLog :: RecordBuilder a -> m (Log b)


instance (LogBuilder xs m ys, Functor m) => LogBuilder (Data x,xs) m (Data x,ys) where
    buildLog b = (fmap.fmap) (x,) $ buildLog $ RecordBuilder xs where
        (x,xs) = fromRecordBuilder b


instance (LogBuilder (Data x,xs) m ys, LogBuilder xs m (Data y,()), Monad m) => LogBuilder (Data x,xs) m (Data y,ys) where
    buildLog b = do
        let (x,xs) = fromRecordBuilder b
        Log ys     <- buildLog b
        Log (y,()) <- buildLog $ RecordBuilder xs
        return $ Log (y, ys)
        

instance Monad m => LogBuilder a m () where
    buildLog _ = return $ Log ()

instance (Functor m, Applicative m, DataGetter y m, LogBuilder () m ys) => LogBuilder () m (Data y,ys) where
    buildLog b = fmap Log $ (,) <$> getData <*> (unLog <$> buildLog b)


type LogBuilder' a m = LogBuilder a m (LogFormat m)




buildLog' :: (Monad m, Applicative m, LogBuilder' a m) => RecordBuilder a -> m (Log (LogFormat m))
buildLog' = buildLog

class LogConstructor d m where
    mkLog :: MonadLogger m => RecordBuilder d -> m ()

instance (LogBuilder' d m) => LogConstructor d m where
    mkLog d = do
        l <- buildLog' d
        appendLog l


----------------------------------------------------------------------
-- Handler & HandlerWrapper
----------------------------------------------------------------------


-- !!! dorobic formattery i filtracje do handlerow!
mkHandler2 :: String -> (Log l -> m ()) -> Handler2 m l
mkHandler2 name f = Handler2 name f [] Nothing

data Handler2 m l = Handler2 { _name2     :: String
                             , _action2   :: Log l -> m ()
                             , _children2 :: [Handler2 m l]
                             , _level2    :: Maybe Int
                             }

makeLenses ''Handler2

topHandler2 = mkHandler2 "TopHandler" (\_ -> return ())

instance Show (Handler2 m l) where
    show (Handler2 n _ _ pr) = "Handler " <> n <> " " <> show pr


-- === Handlers ===

--class LogHandler h m msg where
--    handle :: Handler msg m h -> Log msg -> m (Handler msg m h)

printHandler2 = mkHandler2 "PrintHandler" $ handle2

handle2 l = do
        liftIO $ putDoc $ runFormatter foo l
        liftIO $ putStrLn ""


addChildHandler2 h ph = ph & children2 %~ (h:)


-- === Loggers ===

newtype LoggerT2 l m a = LoggerT2 { fromLoggerT2 :: StateT (Handler2 (LoggerT2 l m) l) m a } deriving (Monad, MonadIO, Applicative, Functor)

runLoggerT2 :: (Functor m, Monad m) => LoggerT2 l m b -> m b
runLoggerT2 = fmap fst . flip runStateT topHandler2 . fromLoggerT2

type instance LogFormat (LoggerT2 l m) = l


getTopHandler = LoggerT2 State.get
putTopHandler = LoggerT2 . State.put

instance (Monad m, Functor m) => MonadLogger (LoggerT2 l m) where
    appendLog l = runHandler2 l =<< getTopHandler


runHandler2 :: (Applicative m, Monad m) => Log l -> Handler2 m l -> m ()
runHandler2 l h = (h^.action2) l <* mapM (runHandler2 l) (h^.children2)


instance (Monad m, Functor m) => MonadLoggerHandler (Handler2 (LoggerT2 l m) l) (LoggerT2 l m) where
    addHandler h = do
        topH <- getTopHandler
        putTopHandler $ addChildHandler2 h topH


--instance (Monad m, Applicative m) => MonadLoggerHandler (HandlerWrapper s (LoggerT s m)) (LoggerT s m) where
--    addHandler (HandlerWrapper h) = withLogState (withHandlerWrapper $ addChildHandler h)

----------------------------------------------------------------------
-- Other
----------------------------------------------------------------------




debug :: (MonadLogger m, LogConstructor (Data Lvl, (Data Msg, ())) m) => String -> m ()
debug     = simpleLog Debug
info      = simpleLog Info
notice    = simpleLog Notice
warning   = simpleLog Warning
error     = simpleLog Error
critical  = simpleLog Critical
alert     = simpleLog Alert
panic     = simpleLog Panic



--flushM = flushMe =<< get



simpleLog = log empty

log :: (Show pri, Enum pri, MonadLogger m, LogConstructor (Data Lvl, (Data Msg, r)) m)
    => RecordBuilder r -> pri -> String -> m ()
log d pri msg = do
#ifdef NOLOGS
    return ()
#else
    mkLog $ appData Lvl (mkLevel pri)
          $ appData Msg msg
          $ d
#endif








-------------------------------------------------------------------------


newtype PriorityLoggerT pri m a = PriorityLoggerT { fromPriorityLoggerT :: StateT pri m a } deriving (Monad, MonadIO, Applicative, Functor, MonadTrans)

type instance LogFormat (PriorityLoggerT pri m) = LogFormat m


runPriorityLoggerT pri = fmap fst . flip runStateT pri . fromPriorityLoggerT


getPriority = PriorityLoggerT State.get

setPriority :: Monad m => pri -> PriorityLoggerT pri m ()
setPriority = PriorityLoggerT . State.put



instance (MonadLogger m, LogConstructor d m, LookupDataSet Lvl d, Enum pri) => LogConstructor d (PriorityLoggerT pri m) where
    mkLog d = do
        priLimit <- getPriority
        let LevelData pri _ = readData Lvl d
        if (fromEnum priLimit) <= pri then lift $ mkLog d
                                      else return ()

-------------------------------------------------------------------------


newtype ThreadedLogger m a = ThreadedLogger { fromThreadedLogger :: ReaderT (InChan (ChMsg m)) m a } deriving (Monad, MonadIO, Applicative, Functor)

instance MonadTrans ThreadedLogger where
    lift = ThreadedLogger . lift

--newtype ThreadedLogger l m a = ThreadedLogger { fromThreadedLogger :: ReaderT (InChan (Log l)) m a } deriving (Monad, MonadIO, Applicative, Functor, MonadTrans)

data ChMsg m = ChMsg (Log (LogFormat m)) | End

runThreadedLogger :: MonadIO m => ThreadedLogger m a -> m a
runThreadedLogger m = do
    (inChan, outChan) <- liftIO newChan
    liftIO . forkIO $ do flip runReaderT inChan . fromThreadedLogger $ m
                         --liftIO $ writeChan inChan End
    flip runReaderT inChan . fromThreadedLogger $ m
    --let loop = do
    --    l <- liftIO $ readChan outChan
    --    case l of
    --        End -> return ()
    --        _   -> loop
    --loop
    --return ()

type instance LogFormat (ThreadedLogger m) = LogFormat m

getChan = ThreadedLogger Reader.ask

instance (MonadIO m, LogBuilder d (ThreadedLogger m) (LogFormat m)) => LogConstructor d (ThreadedLogger m) where
    mkLog d = do
        l  <- buildLog' d
        ch <- getChan
        liftIO $ writeChan ch (ChMsg l)

-------------------------------------------------------------------------


type StdLogger2 m a = LoggerX2 (Lvl, Msg) m a

type StdTypes s = Insert Lvl (Insert Msg s) 

type LoggerX2 l m a = LoggerT2 (MapRTuple Data (Tuple2RTuple l)) m a

--type StdLogger2 m a = LoggerX2 (Lvl, Msg) m a

--type LoggerX2 s m a = WriterLogger (RTuple2Tuple (MapRTuple Data (StdTypes (Tuple2RTuple s)))) m a
--type LoggerX2 s m a = WriterLogger (MapRTuple Data (StdTypes s)) m a

--test2 = do
--    debug "subrutine"

test = do
    --let h = flushHandler `addChildHandler` printHandler
    addHandler printHandler2
    debug "running subrutine"

    --x <- runWriterLoggerT $ runDupLogger test2

    --liftIO $ print x

    addHandler printHandler2


    debug "debug1"
    --setPriority Debug

    debug "debug2"
    info "info"
    warning "warning"

    --fail "oh no"

    --flush
    liftIO $ print "---"

    critical "ola"

    --mkLog (0::Int) "hello"

    return ()



--instance Num Level

main = do
    --print =<< (runLoggerT2 ( (runPriorityLoggerT Warning test) :: StdLogger2 IO () ))
    --print =<< (runLoggerT2 ( test :: StdLogger2 IO ()   ))
    print =<< (runLoggerT2 ( (runThreadedLogger test) :: StdLogger2 IO ()   ))

    --print =<< (runPriorityLoggerT 1 test)
    --print =<< (runLoggerT (test :: StdLogger IO () ))

    --print =<< (fmap snd $ runWriterLoggerT (test2 :: StdLogger2 IO () ))
    return ()





data OneTuple a = OneTuple a deriving Show


--class RTupleConv r t | t -> r, r -> t where
--    t2r :: t -> r
--    r2t :: r -> t

--instance RTupleConv () () where
--    t2r = id
--    r2t = id
--instance RTupleConv (a,()) (OneTuple a) where
--    t2r (OneTuple a) = (a,())
--    r2t (a,()) = OneTuple a
--instance RTupleConv (t1,(t2,())) (t1,t2) where
--    t2r (t1,t2) = (t1,(t2,()))
--    r2t (t1,(t2,())) = (t1,t2)
--instance RTupleConv (t1,(t2,(t3,()))) (t1,t2,t3) where
--    t2r (t1,t2,t3) = (t1,(t2,(t3,())))
--    r2t (t1,(t2,(t3,()))) = (t1,t2,t3)
--instance RTupleConv (t1,(t2,(t3,(t4,())))) (t1,t2,t3,t4) where
--    t2r (t1,t2,t3,t4) = (t1,(t2,(t3,(t4,()))))
--    r2t (t1,(t2,(t3,(t4,())))) = (t1,t2,t3,t4)
--instance RTupleConv (t1,(t2,(t3,(t4,(t5,()))))) (t1,t2,t3,t4,t5) where
--    t2r (t1,t2,t3,t4,t5) = (t1,(t2,(t3,(t4,(t5,())))))
--    r2t (t1,(t2,(t3,(t4,(t5,()))))) = (t1,t2,t3,t4,t5)
--instance RTupleConv (t1,(t2,(t3,(t4,(t5,(t6,())))))) (t1,t2,t3,t4,t5,t6) where
--    t2r (t1,t2,t3,t4,t5,t6) = (t1,(t2,(t3,(t4,(t5,(t6,()))))))
--    r2t (t1,(t2,(t3,(t4,(t5,(t6,())))))) = (t1,t2,t3,t4,t5,t6)
--instance RTupleConv (t1,(t2,(t3,(t4,(t5,(t6,(t7,()))))))) (t1,t2,t3,t4,t5,t6,t7) where
--    t2r (t1,t2,t3,t4,t5,t6,t7) = (t1,(t2,(t3,(t4,(t5,(t6,(t7,())))))))
--    r2t (t1,(t2,(t3,(t4,(t5,(t6,(t7,()))))))) = (t1,t2,t3,t4,t5,t6,t7)
--instance RTupleConv (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,())))))))) (t1,t2,t3,t4,t5,t6,t7,t8) where
--    t2r (t1,t2,t3,t4,t5,t6,t7,t8) = (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,()))))))))
--    r2t (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,())))))))) = (t1,t2,t3,t4,t5,t6,t7,t8)
--instance RTupleConv (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,()))))))))) (t1,t2,t3,t4,t5,t6,t7,t8,t9) where
--    t2r (t1,t2,t3,t4,t5,t6,t7,t8,t9) = (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,())))))))))
--    r2t (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,()))))))))) = (t1,t2,t3,t4,t5,t6,t7,t8,t9)
--instance RTupleConv (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,(t10,())))))))))) (t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) where
--    t2r (t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) = (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,(t10,()))))))))))
--    r2t (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,(t10,())))))))))) = (t1,t2,t3,t4,t5,t6,t7,t8,t9,t10)

type family Tuple2RTuple a where
    Tuple2RTuple ()                               = ()
    Tuple2RTuple (t1,t2)                          = (t1,(t2,()))
    Tuple2RTuple (t1,t2,t3)                       = (t1,(t2,(t3,())))
    Tuple2RTuple (t1,t2,t3,t4)                    = (t1,(t2,(t3,(t4,()))))
    Tuple2RTuple (t1,t2,t3,t4,t5)                 = (t1,(t2,(t3,(t4,(t5,())))))
    Tuple2RTuple (t1,t2,t3,t4,t5,t6)              = (t1,(t2,(t3,(t4,(t5,(t6,()))))))
    Tuple2RTuple (t1,t2,t3,t4,t5,t6,t7)           = (t1,(t2,(t3,(t4,(t5,(t6,(t7,())))))))
    Tuple2RTuple (t1,t2,t3,t4,t5,t6,t7,t8)        = (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,()))))))))
    Tuple2RTuple (t1,t2,t3,t4,t5,t6,t7,t8,t9)     = (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,())))))))))
    Tuple2RTuple (t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) = (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,(t10,()))))))))))
    Tuple2RTuple t                                = (t,())

type family RTuple2Tuple a where
    RTuple2Tuple ()                                                    = ()
    RTuple2Tuple (t1,(t2,()))                                          = (t1,t2)
    RTuple2Tuple (t1,(t2,(t3,())))                                     = (t1,t2,t3)
    RTuple2Tuple (t1,(t2,(t3,(t4,()))))                                = (t1,t2,t3,t4)
    RTuple2Tuple (t1,(t2,(t3,(t4,(t5,())))))                           = (t1,t2,t3,t4,t5)
    RTuple2Tuple (t1,(t2,(t3,(t4,(t5,(t6,()))))))                      = (t1,t2,t3,t4,t5,t6)
    RTuple2Tuple (t1,(t2,(t3,(t4,(t5,(t6,(t7,())))))))                 = (t1,t2,t3,t4,t5,t6,t7)
    RTuple2Tuple (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,()))))))))            = (t1,t2,t3,t4,t5,t6,t7,t8)
    RTuple2Tuple (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,())))))))))       = (t1,t2,t3,t4,t5,t6,t7,t8,t9)
    RTuple2Tuple (t1,(t2,(t3,(t4,(t5,(t6,(t7,(t8,(t9,(t10,())))))))))) = (t1,t2,t3,t4,t5,t6,t7,t8,t9,t10)
    RTuple2Tuple (t,())                                                = t



type family Insert t set where
  Insert t ()    = (t,())
  Insert t (t,x) = (t,x)
  Insert t (a,x) = (a,Insert t x)


type family MapRTuple (f :: * -> *) tup where
    MapRTuple f () = ()
    MapRTuple f (a,as) = (f a, MapRTuple f as)

class MapRTuple2 f tup tup' | f tup -> tup'
    where mapRTuple :: f -> tup -> tup'

instance MapRTuple2 f () () where
    mapRTuple _ = id

instance MapRTuple2 (a -> b) as bs => MapRTuple2 (a -> b) (a,as) (b,bs) where
    mapRTuple f (a,as) = (f a, mapRTuple f as)



-- TODO:
--   filters
--   proper handler formatting