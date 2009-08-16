// ネームスペース
if ( typeof container == "undefined" ) {
  container = {};
}

container.VERSION = "0.4.0";

/**
 * コンテナ
 * @param {Function} module コンポーネント定義を行う関数。
 */
container.Container = function ( module ) {
    var binder = new container.Binder( {} );
    module( binder );
    this.defs = binder.defs;

    // 循環生成防止用のフィールド。作成中のモジュールの一覧が入る。
    this.creating = [];

    // 名前でキャッシュを作っておく。
    // EagerSingletonなオブジェクトがあれば生成。
    this.typeCache = {};
    this.nameCache = {};
    var thiz = this;
    this.eachComponentDef( function( def ) {
        if ( def && def[container.Annotation.Container]
            && def[container.Annotation.Container][container.Annotation.Scope] == container.Scope.EagerSingleton ) {
            thiz.create( def );
        }
        // 名前でキャッシュ
        if ( def && def[container.Annotation.Container]
            && def[container.Annotation.Container][container.Annotation.Name] ) {
            var name = def[container.Annotation.Container][container.Annotation.Name];
            if ( !thiz.nameCache[name] ) {
                thiz.nameCache[name] = []
            }
            thiz.nameCache[name].push( def );
        }
    });
}
container.Container.prototype = {
    /**
     * コンポーネント名またはcontainer.Typeに対応するオブジェクトを取得します。
     *
     * @param {String or container.Type} nameOrType コンポーネント名またはcontainer.Type
     * @return 対応するオブジェクト。複数のコンポーネントがマッチした場合、最初の1つを返します。
     */
    get: function( nameOrType ){
        if ( nameOrType instanceof container.Type ) {
            // キャッシュがなければスキャン
            if ( !this.typeCache[nameOrType] ) {
                this._createTypeCahce( nameOrType );
            }
            if ( this.typeCache[nameOrType].length > 0 ) {
                return this.create( this.typeCache[nameOrType][0]);
            } else {
            	throw container.createError( new Error(),
                    container.ErrorCode.ComponentNotFound,
                    "component not found.name=" + nameOrType, {"nameOrType":nameOrType} );
            }
        } else {
            if ( this.nameCache[nameOrType] && this.nameCache[nameOrType].length > 0 ) {
                return this.create( this.nameCache[nameOrType][0]);
            } else {
            	throw container.createError( new Error(),
                    container.ErrorCode.ComponentNotFound,
                    "component not found.name=" + nameOrType, {"nameOrType":nameOrType} );
            }
        }
    },
    /**
     * コンポーネント名またはcontainer.Typeに対応するオブジェクトをすべて取得します。
     *
     * @param {String or container.Type} nameOrType コンポーネント名またはcontainer.Type
     * @return 対応するオブジェクトの配列
     */
    gets: function( nameOrType ){
        var objects = [];
        if ( nameOrType instanceof container.Type ) {
            // キャッシュがなければスキャン
            if ( !this.typeCache[nameOrType] ) {
                this._createTypeCahce( nameOrType );
            }
            var defs = this.typeCache[nameOrType]
            for ( var i=0; i < defs.length; i++ ) {
                objects.push( this.create( defs[i]) );
            }
        } else {
            if ( this.nameCache[nameOrType] ) {
                var defs = this.nameCache[nameOrType];
                for ( var i=0; i < defs.length; i++ ) {
                    objects.push( this.create( defs[i]) );
                }
            }
        }
        return objects;
    },
    /**
     * コンテナを破棄します。
     */
    destroy: function(  ) {
        var thiz = this;
        this.eachComponentDef( function( def ) {
            if ( !def.instance ){ return; }
            var obj = def.instance;
            var config = def[container.Annotation.Container];
            if ( !config || !config[container.Annotation.Destroy] ) { return; }
            var destroy = config[container.Annotation.Destroy];
            if ( typeof destroy == "string" ) {
                obj[destroy].apply( obj, [this] );
            } else if ( typeof destroy == "function" ) {
                destroy( obj, thiz );
            } else {
            	throw container.createError( new Error(),
                    container.ErrorCode.IllegalDefinition,
                    "illegal destroy method. string or function is supported.", {"def":def} );
            }
            def.instance = null;
        });
    },

    /**
     * コンポーネント定義からコンポーネントを生成する。
     * @param {Hash} def コンポーネント定義
     */
    create: function( def ) {

        // 既に作成済みのインスタンスがあればそれを返す。
        if ( def.instance ) { return def.instance; }

        // 循環チェック
        if ( this._isCreating(def) ) {
           	throw container.createError( new Error(),
                    container.ErrorCode.CircularReference,
                    "circulative component creation.", {"def":def} );
        }

        try {
            this.creating.push( def );

            var obj = def.constractor( this ); // 生成
            def.instance = obj; // キャッシュ

            // アノーテョンで指定した設定とコンテナのコンポーネント設定をマージ
            var config = def[container.Annotation.Container] || {};

            // 自動インジェクション
            if ( config[container.Annotation.AutoInjection] != false ) {
                for ( var property in obj ) {
                    if ( obj[property] instanceof container.inner.Component ) {
                        obj[property]  = this.get( obj[property].name );
                    } else if ( obj[ property] instanceof container.inner.Components ) {
                        obj[property] = this.gets( obj[property].name );
                    } else if ( obj[ property] === container.Inject ) {
                        obj[property]  = this.get( property );
                    } else if ( obj[ property] === container.Injects ) {
                        obj[property]  = this.gets( property );
                    } 
                }
            }
            
            // プロパティインジェクション
            if ( config[container.Annotation.Inject] ) {
                var inject = config[container.Annotation.Inject];
                for ( var f in inject ) {
                    if ( inject[f] instanceof container.inner.Component ) {
                        obj[f] = this.get( inject[f].name );
                    } else if ( inject[f] instanceof container.inner.Components ) {
                        obj[f] = this.gets( inject[f].name );
                    } else if ( inject[f] instanceof container.inner.Provider ) {
                        obj[f] = inject[f].func( obj, this );
                    } else {
                    	  obj[f] = inject[f];
                    }
                }
            }
            
            // 初期化関数の実行
            if ( config[container.Annotation.Initialize] ) {
                var initialize = config[container.Annotation.Initialize];
                if ( typeof initialize == "string" ) {
                    obj[initialize].apply( obj, [this] );
                } else if ( typeof initialize == "function" ) {
                    initialize( obj, this );
                } else {
                	throw container.createError( new Error(),
                        container.ErrorCode.IllegalDefinition,
                        "illegal initialize method. string or function is supported.", {"def":def} );
                }
            }

            // インターセプタの設定
            if ( config[container.Annotation.Intercept] ) {
                var interceptors = config[container.Annotation.Intercept];
                for ( var i=0; i < interceptors.length; i++ ) {
                    this.applyInterceptor( obj, interceptors[i][0], interceptors[i][1] );
                }
            }

            // グローバルインターセプタの設定
            if ( this.defs.interceptors && def.componentType != "function" ) { // バインドメソッドには適用しない。
                for ( var i=0; i < this.defs.interceptors.length; i++ ) {
                    var insterceptor = this.defs.interceptors[i];
                    if ( !insterceptor.nameMatcher) { continue; }
                    if ( insterceptor.nameMatcher instanceof container.Type
                         && insterceptor.nameMatcher.isImplementor(obj) ) {
                        this.applyInterceptor( obj, insterceptor.interceptor, insterceptor.methodMatcher );
                    } else if ( insterceptor.nameMatcher instanceof container.Matcher
                         && config[container.Annotation.Name]
                         && insterceptor.nameMatcher.match( config[container.Annotation.Name] )) {
                        this.applyInterceptor( obj, insterceptor.interceptor, insterceptor.methodMatcher );
                    }
                }
            }

            // シングルトンの場合、次回同じインスタンスを返すのでコンポーネント定義にキャッシュしたままにしておく。
            // プロトタイプの場合破棄
            if ( config[container.Annotation.Scope] == container.Scope.Prototype ) {
                def.instance = undefined;
            }
            return obj;
        } catch ( error ) {
            def.instance = undefined; // エラーの場合破棄
            throw error;
        } finally {
            this.creating.pop();
        }
    },
    /**
     * インターセプターを適用する。
     * @param {Object} target 適用対象のオブジェクト
     */
    applyInterceptor: function( target, interceptor, matcher ) {
      if ( !interceptor || !matcher  ) { return; }
      for ( var f in target ) {
        if ( typeof target[f] == "function" && matcher.match( f ) ) {
          (function() { // f をローカル化するため関数で。
            var x = f;
            var original = target[x];
            target[x] = function( ) {
                // インターセプターを実行する関数に置き換える。
                var mi = new container.MethodInvocation( x, original, target, arguments );
                return interceptor( mi );
            }
          })();
        }
      }
    },
    /**
     * コンポーネント定義を列挙する。
     * @param {Function} block 列挙先。第1引数でコンポーネント定義が渡される。
     */
    eachComponentDef : function( block ) {
        for ( var i = 0; i < this.defs.objects.length; i++ ) {
            if ( block ) {
                block.apply( null, [this.defs.objects[i]] );
            }
        }
    },
    _createTypeCahce: function( nameOrType ) {
        var list = [];
        var self = this;
        this.eachComponentDef( function( def ){
            // 循環する場合は対象に含めない。
            if ( self._isCreating(def) && !def.instance ) { return }
            var obj = self.create( def );
            if ( nameOrType.isImplementor( obj ) ) {
                list.push( def );
            }
        });
        this.typeCache[nameOrType] = list;
    },
    _isCreating: function(def) {
        for ( var i=0; i < this.creating.length; i++ ) {
            if ( def === this.creating[i] ) {
                return true;
            }
        }
        return false;
    }
}

/**
 * バインダー
 * @param {Hash} defs コンポーネント定義
 * @param {String} namespace ネームスペース
 */
container.Binder = function( defs, namespace ){
    this.defs = defs;
    this.namespace = namespace;
}
container.Binder.prototype = {

    /**
     * コンポーネントを登録する
     * @param {Function} clazz コンポーネントクラス
     * @return コンポーネント定義オブジェクト
     */
    bind: function( clazz ) {
        return this._bind( "object", clazz.prototype.meta, function() {
            return new clazz();
        });
    },

    /**
     * 条件にマッチするコンポーネントメソッドを登録する。
     *
     * - Typeまたは名前にマッチするコンポーネントの指定したメソッドをコンポーネントとして登録する。
     * - 複数のコンポーネントがある場合、最初に見つかったTypeまたは名前にマッチするコンポーネントのメソッドが登録される。
     *
     * @param {String or container.Type} nameOrType コンポーネント名またはcontainer.Type
     * @param {String} methodName メソッド名
     * @return コンポーネント定義オブジェクト
     */
    bindMethod: function( nameOrType, methodName ) {
        var self = this;
        return this._bind( "function", null, function( container ) {
            var obj = container.get( nameOrType );
            if (!obj) {
            	throw container.createError( new Error(),
                    container.ErrorCode.ComponentNotFound,
                    "component not found.name=" + nameOrType, {"nameOrType":nameOrType} );
            }
            return self._createBindMethod( obj, methodName );
        });
    },


    /**
     *  条件にマッチするコンポーネントメソッドの配列を登録する。
     *
     * - Typeまたは名前にマッチするコンポーネントの指定したメソッドをコンポーネントとして登録する。
     * - 複数のコンポーネントがある場合、Typeまたは名前にマッチするコンポーネントメソッドの配列が登録される。
     *
     * @param {String or container.Type} nameOrType コンポーネント名またはcontainer.Type
     * @param {String} methodName メソッド名
     * @return コンポーネント定義オブジェクト
     */
    bindMethods: function( nameOrType, methodName ) {
        var self = this;
        return this._bind( "function", null, function( container ) {
            var objs = container.gets( nameOrType );
            var list = [];
            for ( var i=0; i<objs.length;i++ ) {
                 list.push( self._createBindMethod( objs[i], methodName ) );
            }
            return list;
        });
    },

    /**
     * プロバイダが返す値をコンポーネントとして登録する。
     * @param {function} provider プロバイダ関数。第一引数としてcontainer.Containerが渡される。
     * @return コンポーネント定義オブジェクト
     */
    bindProvider: function( provider ) {
        return this._bind( "object", null, provider );
    },

    /**
     * インスタンスをコンポーネントとして登録する。
     * @param {Object} instance インスタンス
     * @return コンポーネント定義オブジェクト
     */
    bindInstance: function( instance ) {
        return this._bind( "object", instance.meta, function() {
            return instance;
        } );
    },

   /**
    * すべてのコンポーネントを対象とするインターセプタを登録する。
    * @param {Fucntion} interceptor インターセプタ関数
    * @param {container.Matcher or container.Type} インターセプタを適用するコンポーネントを選択するcontainer.Matcher or container.Type
    * @param {container.Matcher} インターセプタを適用するメソッド名を選択するMatcher
    */
    bindInterceptor: function( interceptor, nameMatcherOrType, methodMatcher ) {
       var interceptors = this._getInterceptorDefs();
       interceptors.push( {
           "interceptor":   interceptor,
           "nameMatcher":   nameMatcherOrType,
           "methodMatcher": methodMatcher
       } );
    },
    /**
     * ネームスペースを作成する。
     * @param {String} namespace ネームスペース
     * @param {Function} module コンポーネント定義を行う関数
     */
    ns: function( namespace, module ) {
       if ( this.namespace ) {
          namespace = this.namespace + "." + namespace;
       }
       module( new container.Binder( this.defs, namespace ) );
    },

    _bind: function( type, meta, constractor ) {
        var objectDef = this._clone( meta );
        objectDef.constractor = constractor;
        objectDef.componentType = type;
        var list = this._getObjectDefs();
        list.push( objectDef );
        return new container.Builder( objectDef, this.namespace );
    },
    _getObjectDefs: function( ) {
        if ( !this.defs.objects ) {
            this.defs.objects = [];
        }
        return this.defs.objects;
    },
    _getInterceptorDefs: function( ) {
        if ( !this.defs.interceptors ) {
            this.defs.interceptors = [];
        }
        return this.defs.interceptors;
    },
    _createBindMethod: function(obj, methodName) {
        return function() { return obj[methodName].apply( obj, arguments );}
    },
    _clone: function(org) {
        var tmp = {};
        if ( org && org[container.Annotation.Container] ) {
            org = org[container.Annotation.Container];
            for ( var i in container.Annotation) {
                var a = container.Annotation[i]
                if ( a != container.Annotation.Intercept
                    && a != container.Annotation.Container  ) {
                  tmp[a] = org[a];
                }
            }
            tmp[container.Annotation.Intercept] = [];
            if ( org[container.Annotation.Intercept] ) {
                var list = org[container.Annotation.Intercept];
                for ( var i=0; i < list.length; i++ ) {
                    tmp[container.Annotation.Intercept].push( list[i] );
                }
            }
        }
        var res = {};
        res[container.Annotation.Container] = tmp;
        return res;
    }
}
container.Builder = function( def, namespace ){
    if ( !def[ container.Annotation.Container ] ) {
        def[ container.Annotation.Container ] = {};
    }
    this.def = def[ container.Annotation.Container ];
    if ( !this.def[container.Annotation.Intercept] ) {
        this.def[container.Annotation.Intercept] = [];
    }
    this.namespace = namespace;
}
container.Builder.prototype = {
    /**
     * コンポーネントの名前を設定する。
     * @param {String} name コンポーネント名
     * @return 自身のインスタンス
     */
    to: function( name ) {
        if (this.namespace) {
            name = this.namespace + "." + name;
        }
        this.def[container.Annotation.Name] = name;
        return this;
    },
    /**
     * コンポーネントに注入するプロパティを設定する。
     * @param {Hash} injectionParameter コンポーネントに注入するプロパティ
     * @return 自身のインスタンス
     */
    inject: function( injectionParameter ) {
        this.def[container.Annotation.Inject] = injectionParameter;
        return this;
    },
    /**
     * コンポーネント生成時に実行される初期化関数を設定する。
     * @param {Function or String} initializeFunctionOrName 初期化関数または初期化時に呼び出す関数名
     * @return 自身のインスタンス
     */
    initialize:function( initializeFunctionOrName ) {
        this.def[container.Annotation.Initialize] = initializeFunctionOrName;
        return this;
    },
    /**
     * コンテナの破棄時にに実行される破棄関数を設定する。
     *
     * 注意:破棄関数が呼ばれるのは、SingletonまたはEagerSingletonコンポーネントのみです。
     *
     * @param {Function or String} destroyFunctionOrName 破棄関数または破棄時に呼び出す関数名
     */
    destroy:function( destroyFunctionOrName ) {
        this.def[container.Annotation.Destroy] = destroyFunctionOrName;
        return this;
    },
    /**
     * コンポーネントのスコープを設定する。
     * @param {String} scope スコープ。container.Scopeの値が指定可能
     */
    scope:function( scope ) {
        this.def[container.Annotation.Scope] = scope;
        return this;
    },
    /**
     * コンポーネントにインターセプタを追加する。
     * @param {Function} interceptor インターセプタ関数
     * @param {container.Matcher} matcher フックするメソッド名を示すcontainer.Matcher
     */
    intercept:function( interceptor, matcher ) {
        this.def[container.Annotation.Intercept].push( [ interceptor, matcher ] );
        return this;
    }
}

/**
 * 指定した条件にマッチするか評価するオブジェクト。
 * @param {RegExp} or {Array<RegExp>} or {Function} includes
 *     マッチ条件。
 *     正規表現、正規表現の配列、または関数で指定する。
 *       -正規表現       .. 値が正規表現にマッチするか
 *       -正規表現の配列 .. 値が正規表現のいずれかにマッチするか
 *       -関数           .. 関数の実行結果がtrueであるか。(引数として評価対象の値が渡される。)
 * @param {RegExp} or {Array<RegExp>} or {Function} excludes
 *     マッチ対象外を指定する条件。includeに含まれていてもexcludeにマッチする場合、マッチしないと見なされる。
 *     正規表現、正規表現の配列、または関数で指定する。
 *       -正規表現       .. 値が正規表現にマッチするか
 *       -正規表現の配列 .. 値が正規表現のいずれかにマッチするか
 *       -関数           .. 関数の実行結果がtrueであるか。(引数として評価対象の値が渡される。)
 */
container.Matcher = function ( includes, excludes ){

    if ( includes && !(includes instanceof Array
        || includes instanceof RegExp
        || includes instanceof Function )){
        throw container.createError( new Error(),
            container.ErrorCode.IllegalArgument,
            "Illegal includes.", {} );
    }
    if ( excludes && !(excludes instanceof Array
        || excludes instanceof RegExp
        || excludes instanceof Function )){
        throw container.createError( new Error(),
            container.ErrorCode.IllegalArgument,
            "Illegal excludes.", {} );
    }
    this.excludes = excludes;
    this.includes = includes;
}
container.Matcher.prototype = {

    /**
     * 評価値が条件にマッチするか評価する。
     * @param {String} value 評価値
     * @return マッチする場合true
     */
    match: function( value ){
        if ( this.excludes && this.getEvaluator( this.excludes)(value) ) {
            return false;
        }
        if ( this.includes && this.getEvaluator( this.includes)(value) ) {
            return true;
        }
        return false
    },
    getEvaluator: function( includes ) {
        if ( includes  instanceof Array ){
            return function( value ) {
                for (var i=0; i<includes.length; i++) {
                    if ( includes[i] instanceof RegExp && includes[i].test( value )){
                        return true;
                    }
                }
                return false;
            };
        } else if ( includes instanceof RegExp ){
            return function( value ) {
                return includes.test( value );
            };
        } else if ( includes instanceof Function ){
            return includes;
        }
    }
}

/**
 * インターセプタの引数として渡されるオブジェクト
 * @param {String} name インターセプトされた関数名
 * @param {Function} original インターセプトされたオリジナルの関数
 * @param {Object} target インターセプトされたオブジェクト
 * @param {Object} arg 関数に渡された引数(arguments)
 */
container.MethodInvocation = function( name, original, target, arg ) {
    this.name = name;
    this.original = original;
    this.arg = arg;
    this.target = target;
}
container.MethodInvocation.prototype = {

    /**
     * インターセプトされたオブジェクトを取得する。
     * @return インターセプトされたオブジェクト
     */
    getThis: function() { return this.target; },

    /**
     * 現在の引数を使用して、オリジナルの関数を実行する。
     * 引数を改変するには、getArguments()の戻り値を直接編集する。
     * @return オリジナルの関数の実行結果
     */
    proceed: function() {
        return this.original.apply( this.target, this.arg );
    },
    /**
     * 関数に渡された引数を取得する。
     * @return 関数に渡された引数。
     */
    getArguments: function() { return this.arg; },
    /**
     * オリジナルの関数を取得する。
     * @return オリジナルの関数
     */
    getOriginalMethod: function() { return this.original; },
    /**
     * インターセプトされた関数名を取得する。
     * @return インターセプトされた関数名
     */
    getMethodName: function() { return this.name; }
}

/**
 * 内部クラス。
 */
container.inner = {}
container.inner.Component = function( name ) {
    this.name = name;
}
container.inner.Components = function( name ) {
    this.name = name;
}
container.inner.Provider = function( func ) {
    this.func = func;
}

/**
 * 例外にメッセージ等を設定する。
 * @param {Error} エラー
 * @param {int} code エラーコード。container.Exception.ErrorCodeの定数を参照。
 * @param {String} message エラーメッセージ
 * @param {Hash} options 補足情報
 */
container.createError = function( error, code, message, options ) {
    error.errorCode = code;
    error.message = message;
    error.options = options;
    error.name = "container.Exception";
    return error;
}

/**
 * エラーコード
 */
container.ErrorCode = {
    // 引数が不正
    IllegalArgument: 1,
    // コンポーネント定義が存在しない。
    ComponentNotFound: 100,
    // コンポーネント定義が不正。
    IllegalDefinition: 101,
    // 循環参照
    CircularReference: 102
}

container.Annotation = {
    Container:   "@Container",
    Name:        "@Name",
    Inject:      "@Inject",
    Initialize:  "@Initialize",
    Destroy:     "@Destroy",
    Intercept:   "@Intercept",
    Scope:       "@Scope",
    AutoInjection: "@AutoInjection"
}
container.Scope = {
    Singleton:        "Singleton",
    Prototype:        "Prototype",
    EagerSingleton:   "EagerSingleton"
}

// ユーティリティ
/**
 * すべてにマッチするcontainer.Matcherを作成する。
 */
container.any = function() {
    return new container.Matcher( /.*/ );
}
/**
 * コンポーネントを挿入するインジェクション指定を作成する。
 */
container.component = function( nameOrType ) {
    return new container.inner.Component( nameOrType );
}
/**
 * コンポーネントの配列を挿入するインジェクション指定を作成する。
 */
container.components = function( nameOrType ) {
    return new container.inner.Components( nameOrType );
}
/**
 * 関数の実行結果を挿入するインジェクション指定を作成する。
 */
container.provides = function( func ) {
    return new container.inner.Provider( func );
}

/**
 * 自動インジェクションの指定
 */
container.Inject = function( nameOrType ) {
  return container.component( nameOrType );
}
container.Injects = function( nameOrType ) {
  return container.components( nameOrType );
}

/**
 * タイプ
 */
container.Type = function() {}
container.Type.prototype = {

    /**
     * 同じタイプであるか評価します。
     * @param {container.Type} that タイプ
     * @return 同じであればtrue
     */
    equals: function( that ) {},

    /**
     * オブジェクトがTypeの条件を満たすか評価します。
     * @param {Object} obj オブジェクト
     * @return 条件を満たす場合true
     */
    isImplementor: function( obj ) {}
}

/**
 * ユーテイリティ
 */
container.types =  {

    /**
     * 指定されたメソッドをすべて実装することを示すTypeを生成する。
     * @param {String or Regexp or container.Type} methods メソッド名、正規表現またはcontainer.Type
     * @return 指定されたメソッドをすべて実装することを示すcontainer.Type
     */
    has: function() {
        return new container.inner.types.And( container.types._createTypes( arguments ));
    },
    /**
     * 指定されたメソッドのいずれかを実装することを示すTypeを生成する。
     * @param {String or Regexp or container.Type} methods メソッド名、正規表現またはcontainer.Type
     * @return 指定されたメソッドのいずれかを実装することを示すcontainer.Type
     */
    hasAny: function() {
        return new container.inner.types.Or( container.types._createTypes( arguments ));
    },

    /**
     * 指定された型の条件を満たさないことを示すTypeを生成する。
     * @param {String or Regexp or container.Type} type メソッド名、正規表現またはcontainer.Type
     * @return 指定された型の条件を満たさないことを示すType
     */
    not: function( type ) {
        return new container.inner.types.Not( container.types._createType(type) );
    },

    _createTypes: function ( list ) {
        var types = [];
        for ( var i=0; i < list.length; i++ ) {
        	types.push( container.types._createType( list[i] ));
        }
        return types;
    },
    _createType: function ( item ) {
        if ( item instanceof RegExp ) {
            return new container.inner.types.RegexpMethod(item);
        } else if ( item instanceof container.Type ) {
            return  item ;
        } else if ( typeof item == "string"  ) {
            return  new container.inner.types.Method(item);
        } else {
            throw "illegal argument.";
        }
    }
}

container.inner.types = {}

/**
 * 完全一致
 */
container.inner.types.Method = function( name ) {
    this.name = name;
}
container.inner.types.Method.prototype = new container.Type();
container.inner.types.Method.prototype.equals = function( that ) {
    if ( !that || !( that instanceof container.inner.types.Method ) ){
        return false;
    }
    return this.name == that.name;
}
container.inner.types.Method.prototype.isImplementor = function( obj ) {
    return typeof obj[this.name] == "function";
}
container.inner.types.Method.prototype.toString = function( ) {
    return  "!container.inner.types.Method:" + this.name;
}


/**
 * 正規表現一致
 */
container.inner.types.RegexpMethod = function( exp ) {
    this.exp = exp;
}
container.inner.types.RegexpMethod.prototype = new container.Type();
container.inner.types.RegexpMethod.prototype.equals = function( that ) {
    if ( !that || !( that instanceof container.inner.types.RegexpMethod ) ){
        return false;
    }
    return this.exp.ignoreCase == that.exp.ignoreCase
        && this.exp.global  == that.exp.global
        && this.exp.source == that.exp.source;
}
container.inner.types.RegexpMethod.prototype.isImplementor = function( obj ) {
    for ( var key in obj ) {
        if ( typeof obj[key] == "function" && this.exp.test( key ) ) {
            return true;
        }
    }
    return false;
}
container.inner.types.RegexpMethod.prototype.toString = function( ) {
    return  "!container.inner.types.RegexpMethod:/" + this.exp.source + "/"
        + this.exp.ignoreCase + "/" + this.exp.global ;
}


/**
 * And
 */
container.inner.types.And = function(types) {
    this.types = types;
}
container.inner.types.And.prototype = new container.Type();
container.inner.types.And.prototype.equals = function( that ) {
    if ( !that || !( that instanceof container.inner.types.And ) ){
        return false;
    }
    if ( this.types.length != that.types.length ){
        return false;
    }
    for ( var i=0; i < this.types.length; i++ ) {
        var a = this.types[i];
        var b = that.types[i];
        if ( !a.equals(b) ) { return false; }
    }
    return true;
}
container.inner.types.And.prototype.isImplementor = function( obj ) {
    for ( var i=0; i < this.types.length; i++ ) {
        if ( !this.types[i].isImplementor(obj)) {
            return false;
        }
    }
    return true;
}
container.inner.types.And.prototype.toString = function( ) {
    var str = "!container.inner.types.And:[";
    for ( var i=0; i < this.types.length; i++ ) {
        str += this.types[i].toString() + ",";
    }
    str += "]";
    return str;
}

/**
 * Or
 */
container.inner.types.Or = function(types) {
    this.types = types;
}
container.inner.types.Or.prototype = new container.Type();
container.inner.types.Or.prototype.equals = function( that ) {
    if ( !that || !( that instanceof container.inner.types.Or ) ){
        return false;
    }
    if ( this.types.length != that.types.length ){
        return false;
    }
    for ( var i=0; i < this.types.length; i++ ) {
        var a = this.types[i];
        var b = that.types[i];
        if ( !a.equals(b) ) { return false; }
    }
    return true;
}
container.inner.types.Or.prototype.isImplementor = function( obj ) {
    for ( var i=0; i < this.types.length; i++ ) {
        if ( this.types[i].isImplementor(obj)) {
            return true;
        }
    }
    return false;
}
container.inner.types.Or.prototype.toString = function( ) {
    var str = "!container.inner.types.Or:[";
    for ( var i=0; i < this.types.length; i++ ) {
        str += this.types[i].toString() + ",";
    }
    str += "]";
    return str;
}

/**
 * Not
 */
container.inner.types.Not = function(type) {
    this.type = type;
}
container.inner.types.Not.prototype = new container.Type();
container.inner.types.Not.prototype.equals = function( that ) {
    if ( !that || !( that instanceof container.inner.types.Not ) ){
        return false;
    }
    return this.type.equals( that.type );
}
container.inner.types.Not.prototype.isImplementor = function( obj ) {
    return  !this.type.isImplementor(obj);
}
container.inner.types.Not.prototype.toString = function( ) {
    return "!container.inner.types.Not:[" + this.type.toString() + "]";
}
