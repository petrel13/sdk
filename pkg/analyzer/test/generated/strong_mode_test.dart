// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.strong_mode_test;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:front_end/src/base/errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrongModeLocalInferenceTest);
    defineReflectiveTests(StrongModeStaticTypeAnalyzer2Test);
    defineReflectiveTests(StrongModeTypePropagationTest);
  });
}

/**
 * Strong mode static analyzer local type inference tests
 */
@reflectiveTest
class StrongModeLocalInferenceTest extends ResolverTestCase {
  TypeAssertions _assertions;

  Asserter<DartType> _isDynamic;
  Asserter<InterfaceType> _isFutureOfDynamic;
  Asserter<InterfaceType> _isFutureOfInt;
  Asserter<InterfaceType> _isFutureOfNull;
  Asserter<InterfaceType> _isFutureOrOfInt;
  Asserter<DartType> _isInt;
  Asserter<DartType> _isNull;
  Asserter<DartType> _isNum;
  Asserter<DartType> _isObject;
  Asserter<DartType> _isString;

  AsserterBuilder2<Asserter<DartType>, Asserter<DartType>, DartType>
      _isFunction2Of;
  AsserterBuilder<List<Asserter<DartType>>, InterfaceType> _isFutureOf;
  AsserterBuilder<List<Asserter<DartType>>, InterfaceType> _isFutureOrOf;
  AsserterBuilderBuilder<Asserter<DartType>, List<Asserter<DartType>>, DartType>
      _isInstantiationOf;
  AsserterBuilder<Asserter<DartType>, InterfaceType> _isListOf;
  AsserterBuilder2<Asserter<DartType>, Asserter<DartType>, InterfaceType>
      _isMapOf;
  AsserterBuilder<List<Asserter<DartType>>, InterfaceType> _isStreamOf;
  AsserterBuilder<DartType, DartType> _isType;

  AsserterBuilder<Element, DartType> _hasElement;
  AsserterBuilder<DartType, DartType> _hasElementOf;

  @override
  Future<TestAnalysisResult> computeAnalysisResult(Source source) async {
    TestAnalysisResult result = await super.computeAnalysisResult(source);
    if (_assertions == null) {
      _assertions = new TypeAssertions(typeProvider);
      _isType = _assertions.isType;
      _hasElement = _assertions.hasElement;
      _isInstantiationOf = _assertions.isInstantiationOf;
      _isInt = _assertions.isInt;
      _isNull = _assertions.isNull;
      _isNum = _assertions.isNum;
      _isObject = _assertions.isObject;
      _isString = _assertions.isString;
      _isDynamic = _assertions.isDynamic;
      _isListOf = _assertions.isListOf;
      _isMapOf = _assertions.isMapOf;
      _isFunction2Of = _assertions.isFunction2Of;
      _hasElementOf = _assertions.hasElementOf;
      _isFutureOf = _isInstantiationOf(_hasElementOf(typeProvider.futureType));
      _isFutureOrOf =
          _isInstantiationOf(_hasElementOf(typeProvider.futureOrType));
      _isFutureOfDynamic = _isFutureOf([_isDynamic]);
      _isFutureOfInt = _isFutureOf([_isInt]);
      _isFutureOfNull = _isFutureOf([_isNull]);
      _isFutureOrOfInt = _isFutureOrOf([_isInt]);
      _isStreamOf = _isInstantiationOf(_hasElementOf(typeProvider.streamType));
    }
    return result;
  }

  @override
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongMode = true;
    resetWith(options: options);
  }

  test_async_method_propagation() async {
    String code = r'''
      import "dart:async";
      class A {
        Future f0() => new Future.value(3);
        Future f1() async => new Future.value(3);
        Future f2() async => await new Future.value(3);

        Future<int> f3() => new Future.value(3);
        Future<int> f4() async => new Future.value(3);
        Future<int> f5() async => await new Future.value(3);

        Future g0() { return new Future.value(3); }
        Future g1() async { return new Future.value(3); }
        Future g2() async { return await new Future.value(3); }

        Future<int> g3() { return new Future.value(3); }
        Future<int> g4() async { return new Future.value(3); }
        Future<int> g5() async { return await new Future.value(3); }
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      FunctionBody body = test.body;
      Expression returnExp;
      if (body is ExpressionFunctionBody) {
        returnExp = body.expression;
      } else {
        ReturnStatement stmt = (body as BlockFunctionBody).block.statements[0];
        returnExp = stmt.expression;
      }
      DartType type = returnExp.staticType;
      if (returnExp is AwaitExpression) {
        type = returnExp.expression.staticType;
      }
      typeTest(type);
    }

    check("f0", _isFutureOfDynamic);
    check("f1", _isFutureOfDynamic);
    check("f2", _isFutureOfDynamic);

    check("f3", _isFutureOfInt);
    check("f4", _isFutureOfInt);
    check("f5", _isFutureOfInt);

    check("g0", _isFutureOfDynamic);
    check("g1", _isFutureOfDynamic);
    check("g2", _isFutureOfDynamic);

    check("g3", _isFutureOfInt);
    check("g4", _isFutureOfInt);
    check("g5", _isFutureOfInt);
  }

  test_async_propagation() async {
    String code = r'''
      import "dart:async";

      Future f0() => new Future.value(3);
      Future f1() async => new Future.value(3);
      Future f2() async => await new Future.value(3);

      Future<int> f3() => new Future.value(3);
      Future<int> f4() async => new Future.value(3);
      Future<int> f5() async => await new Future.value(3);

      Future g0() { return new Future.value(3); }
      Future g1() async { return new Future.value(3); }
      Future g2() async { return await new Future.value(3); }

      Future<int> g3() { return new Future.value(3); }
      Future<int> g4() async { return new Future.value(3); }
      Future<int> g5() async { return await new Future.value(3); }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      FunctionBody body = test.functionExpression.body;
      Expression returnExp;
      if (body is ExpressionFunctionBody) {
        returnExp = body.expression;
      } else {
        ReturnStatement stmt = (body as BlockFunctionBody).block.statements[0];
        returnExp = stmt.expression;
      }
      DartType type = returnExp.staticType;
      if (returnExp is AwaitExpression) {
        type = returnExp.expression.staticType;
      }
      typeTest(type);
    }

    check("f0", _isFutureOfDynamic);
    check("f1", _isFutureOfDynamic);
    check("f2", _isFutureOfDynamic);

    check("f3", _isFutureOfInt);
    check("f4", _isFutureOfInt);
    check("f5", _isFutureOfInt);

    check("g0", _isFutureOfDynamic);
    check("g1", _isFutureOfDynamic);
    check("g2", _isFutureOfDynamic);

    check("g3", _isFutureOfInt);
    check("g4", _isFutureOfInt);
    check("g5", _isFutureOfInt);
  }

  test_async_star_method_propagation() async {
    String code = r'''
      import "dart:async";
      class A {
        Stream g0() async* { yield []; }
        Stream g1() async* { yield* new Stream(); }

        Stream<List<int>> g2() async* { yield []; }
        Stream<List<int>> g3() async* { yield* new Stream(); }
      }
    ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      BlockFunctionBody body = test.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("g0", _isListOf(_isDynamic));
    check("g1", _isStreamOf([_isDynamic]));

    check("g2", _isListOf(_isInt));
    check("g3", _isStreamOf([(DartType type) => _isListOf(_isInt)(type)]));
  }

  test_async_star_propagation() async {
    String code = r'''
      import "dart:async";

      Stream g0() async* { yield []; }
      Stream g1() async* { yield* new Stream(); }

      Stream<List<int>> g2() async* { yield []; }
      Stream<List<int>> g3() async* { yield* new Stream(); }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      BlockFunctionBody body = test.functionExpression.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("g0", _isListOf(_isDynamic));
    check("g1", _isStreamOf([_isDynamic]));

    check("g2", _isListOf(_isInt));
    check("g3", _isStreamOf([(DartType type) => _isListOf(_isInt)(type)]));
  }

  test_cascadeExpression() async {
    String code = r'''
      class A<T> {
        List<T> map(T a, List<T> mapper(T x)) => mapper(a);
      }

      void main () {
        A<int> a = new A()..map(0, (x) => [x]);
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    CascadeExpression fetch(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      CascadeExpression exp = decl.initializer;
      return exp;
    }

    Element elementA = AstFinder.getClass(unit, "A").element;

    CascadeExpression cascade = fetch(0);
    _isInstantiationOf(_hasElement(elementA))([_isInt])(cascade.staticType);
    MethodInvocation invoke = cascade.cascadeSections[0];
    FunctionExpression function = invoke.argumentList.arguments[1];
    ExecutableElement f0 = function.element;
    _isListOf(_isInt)(f0.type.returnType);
    expect(f0.type.normalParameterTypes[0], typeProvider.intType);
  }

  test_constrainedByBounds1() async {
    // Test that upwards inference with two type variables correctly
    // propogates from the constrained variable to the unconstrained
    // variable if they are ordered left to right.
    String code = r'''
    T f<S, T extends S>(S x) => null;
    void test() { var x = f(3); }
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isInt(call.staticType);
  }

  test_constrainedByBounds2() async {
    // Test that upwards inference with two type variables does
    // propogate from the constrained variable to the unconstrained
    // variable if they are ordered right to left.
    String code = r'''
    T f<T extends S, S>(S x) => null;
    void test() { var x = f(3); }
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isInt(call.staticType);
  }

  test_constrainedByBounds3() async {
    Source source = addSource(r'''
      T f<T extends S, S extends int>(S x) => null;
      void test() { var x = f(3); }
   ''');
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isInt(call.staticType);
  }

  test_constrainedByBounds4() async {
    // Test that upwards inference with two type variables correctly
    // propogates from the constrained variable to the unconstrained
    // variable if they are ordered left to right, when the variable
    // appears co and contra variantly
    String code = r'''
    typedef To Func1<From, To>(From x);
    T f<S, T extends Func1<S, S>>(S x) => null;
    void test() { var x = f(3)(4); }
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isInt(call.staticType);
  }

  test_constrainedByBounds5() async {
    // Test that upwards inference with two type variables does not
    // propogate from the constrained variable to the unconstrained
    // variable if they are ordered right to left, when the variable
    // appears co and contra variantly, and that an error is issued
    // for the non-matching bound.
    String code = r'''
    typedef To Func1<From, To>(From x);
    T f<T extends Func1<S, S>, S>(S x) => null;
    void test() { var x = f(3)(4); }
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.COULD_NOT_INFER]);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isDynamic(call.staticType);
  }

  test_constructorInitializer_propagation() async {
    String code = r'''
      class A {
        List<String> x;
        A() : this.x = [];
      }
   ''';
    CompilationUnit unit = await resolveSource(code);
    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    ConstructorFieldInitializer assignment = constructor.initializers[0];
    Expression exp = assignment.expression;
    _isListOf(_isString)(exp.staticType);
  }

  test_factoryConstructor_propagation() async {
    String code = r'''
      class A<T> {
        factory A() { return new B(); }
      }
      class B<S> extends A<S> {}
   ''';
    CompilationUnit unit = await resolveSource(code);

    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    BlockFunctionBody body = constructor.body;
    ReturnStatement stmt = body.block.statements[0];
    InstanceCreationExpression exp = stmt.expression;
    ClassElement elementB = AstFinder.getClass(unit, "B").element;
    ClassElement elementA = AstFinder.getClass(unit, "A").element;
    expect(resolutionMap.typeForTypeName(exp.constructorName.type).element,
        elementB);
    _isInstantiationOf(_hasElement(elementB))(
        [_isType(elementA.typeParameters[0].type)])(exp.staticType);
  }

  test_fieldDeclaration_propagation() async {
    String code = r'''
      class A {
        List<String> f0 = ["hello"];
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    VariableDeclaration field = AstFinder.getFieldInClass(unit, "A", "f0");

    _isListOf(_isString)(field.initializer.staticType);
  }

  test_functionDeclaration_body_propagation() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      List<int> test1() => [];

      Function2<int, int> test2 (int x) {
        Function2<String, int> inner() {
          return (x) => x.length;
        }
        return (x) => x;
     }
   ''';
    CompilationUnit unit = await resolveSource(code);

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    FunctionDeclaration test1 = AstFinder.getTopLevelFunction(unit, "test1");
    ExpressionFunctionBody body = test1.functionExpression.body;
    assertListOfInt(body.expression.staticType);

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test2");

    FunctionDeclaration inner =
        (statements[0] as FunctionDeclarationStatement).functionDeclaration;
    BlockFunctionBody body0 = inner.functionExpression.body;
    ReturnStatement return0 = body0.block.statements[0];
    Expression anon0 = return0.expression;
    FunctionType type0 = anon0.staticType;
    expect(type0.returnType, typeProvider.intType);
    expect(type0.normalParameterTypes[0], typeProvider.stringType);

    FunctionExpression anon1 = (statements[1] as ReturnStatement).expression;
    FunctionType type1 =
        resolutionMap.elementDeclaredByFunctionExpression(anon1).type;
    expect(type1.returnType, typeProvider.intType);
    expect(type1.normalParameterTypes[0], typeProvider.intType);
  }

  test_functionLiteral_assignment_typedArguments() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, String> l0 = (int x) => null;
        Function2<int, String> l1 = (int x) => "hello";
        Function2<int, String> l2 = (String x) => "hello";
        Function2<int, String> l3 = (int x) => 3;
        Function2<int, String> l4 = (int x) {return 3;};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      return resolutionMap.elementDeclaredByFunctionExpression(exp).type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_assignment_unTypedArguments() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, String> l0 = (x) => null;
        Function2<int, String> l1 = (x) => "hello";
        Function2<int, String> l2 = (x) => "hello";
        Function2<int, String> l3 = (x) => 3;
        Function2<int, String> l4 = (x) {return 3;};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      return resolutionMap.elementDeclaredByFunctionExpression(exp).type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_body_propagation() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, List<String>> l0 = (int x) => ["hello"];
        Function2<int, List<String>> l1 = (String x) => ["hello"];
        Function2<int, List<String>> l2 = (int x) => [3];
        Function2<int, List<String>> l3 = (int x) {return [3];};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    Expression functionReturnValue(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      FunctionBody body = exp.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression;
      }
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    assertListOfString(functionReturnValue(0).staticType);
    assertListOfString(functionReturnValue(1).staticType);
    assertListOfString(functionReturnValue(2).staticType);
    assertListOfString(functionReturnValue(3).staticType);
  }

  test_functionLiteral_functionExpressionInvocation_typedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        (new Mapper<int, String>().map)((int x) => null);
        (new Mapper<int, String>().map)((int x) => "hello");
        (new Mapper<int, String>().map)((String x) => "hello");
        (new Mapper<int, String>().map)((int x) => 3);
        (new Mapper<int, String>().map)((int x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      FunctionExpressionInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return resolutionMap.elementDeclaredByFunctionExpression(exp).type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_functionExpressionInvocation_unTypedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        (new Mapper<int, String>().map)((x) => null);
        (new Mapper<int, String>().map)((x) => "hello");
        (new Mapper<int, String>().map)((x) => "hello");
        (new Mapper<int, String>().map)((x) => 3);
        (new Mapper<int, String>().map)((x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      FunctionExpressionInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return resolutionMap.elementDeclaredByFunctionExpression(exp).type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_functionInvocation_typedArguments() async {
    String code = r'''
      String map(String mapper(int x)) => mapper(null);

      void main () {
        map((int x) => null);
        map((int x) => "hello");
        map((String x) => "hello");
        map((int x) => 3);
        map((int x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return resolutionMap.elementDeclaredByFunctionExpression(exp).type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_functionInvocation_unTypedArguments() async {
    String code = r'''
      String map(String mapper(int x)) => mapper(null);

      void main () {
        map((x) => null);
        map((x) => "hello");
        map((x) => "hello");
        map((x) => 3);
        map((x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return resolutionMap.elementDeclaredByFunctionExpression(exp).type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_methodInvocation_typedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        new Mapper<int, String>().map((int x) => null);
        new Mapper<int, String>().map((int x) => "hello");
        new Mapper<int, String>().map((String x) => "hello");
        new Mapper<int, String>().map((int x) => 3);
        new Mapper<int, String>().map((int x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return resolutionMap.elementDeclaredByFunctionExpression(exp).type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_methodInvocation_unTypedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        new Mapper<int, String>().map((x) => null);
        new Mapper<int, String>().map((x) => "hello");
        new Mapper<int, String>().map((x) => "hello");
        new Mapper<int, String>().map((x) => 3);
        new Mapper<int, String>().map((x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return resolutionMap.elementDeclaredByFunctionExpression(exp).type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_unTypedArgument_propagation() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, int> l0 = (x) => x;
        Function2<int, int> l1 = (x) => x+1;
        Function2<int, String> l2 = (x) => x;
        Function2<int, String> l3 = (x) => x.toLowerCase();
        Function2<String, String> l4 = (x) => x.toLowerCase();
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    Expression functionReturnValue(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      FunctionBody body = exp.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression;
      }
    }

    expect(functionReturnValue(0).staticType, typeProvider.intType);
    expect(functionReturnValue(1).staticType, typeProvider.intType);
    expect(functionReturnValue(2).staticType, typeProvider.intType);
    expect(functionReturnValue(3).staticType, typeProvider.dynamicType);
    expect(functionReturnValue(4).staticType, typeProvider.stringType);
  }

  test_futureOr_assignFromFuture() async {
    // Test a Future<T> can be assigned to FutureOr<T>.
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOrOfInt(invoke.staticType);
  }

  test_futureOr_assignFromValue() async {
    // Test a T can be assigned to FutureOr<T>.
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(T x) => x;
    test() => mk(42);
    ''');
    _isFutureOrOfInt(invoke.staticType);
  }

  test_futureOr_asyncExpressionBody() async {
    // A FutureOr<T> can be used as the expression body for an async function
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) async => x;
    test() => mk(42);
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_asyncReturn() async {
    // A FutureOr<T> can be used as the return value for an async function
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) async { return x; }
    test() => mk(42);
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_await() async {
    // Test a FutureOr<T> can be awaited.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) async => await x;
    test() => mk(42);
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_downwards1() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    Future<int> test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_downwards2() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters when the downwards context is FutureOr
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    FutureOr<int> test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_downwards3() async {
    // Test that downwards inference correctly propogates into
    // arguments.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    Future<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards4() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters when the downwards context is FutureOr
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards5() async {
    // Test that downwards inference correctly pins the type when it
    // comes from a FutureOr
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    FutureOr<num> test() => mk(new Future.value(42));
    ''');
    _isFutureOf([_isNum])(invoke.staticType);
    _isFutureOf([_isNum])(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards6() async {
    // Test that downwards inference doesn't decompose FutureOr
    // when instantiating type variables.
    MethodInvocation invoke = await _testFutureOr(r'''
    T mk<T>(T x) => null;
    FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOrOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards7() async {
    // Test that downwards inference incorporates bounds correctly
    // when instantiating type variables.
    MethodInvocation invoke = await _testFutureOr(r'''
      T mk<T extends Future<int>>(T x) => null;
      FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards8() async {
    // Test that downwards inference incorporates bounds correctly
    // when instantiating type variables.
    // TODO(leafp): I think this should pass once the inference changes
    // that jmesserly is adding are landed.
    MethodInvocation invoke = await _testFutureOr(r'''
    T mk<T extends Future<Object>>(T x) => null;
    FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards9() async {
    // Test that downwards inference decomposes correctly with
    // other composite types
    MethodInvocation invoke = await _testFutureOr(r'''
    List<T> mk<T>(T x) => null;
    FutureOr<List<int>> test() => mk(3);
    ''');
    _isListOf(_isInt)(invoke.staticType);
    _isInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_methods1() async {
    // Test that FutureOr has the Object methods
    MethodInvocation invoke = await _testFutureOr(r'''
    dynamic test(FutureOr<int> x) => x.toString();
    ''');
    _isString(invoke.staticType);
  }

  test_futureOr_methods2() async {
    // Test that FutureOr does not have the constituent type methods
    MethodInvocation invoke = await _testFutureOr(
        r'''
    dynamic test(FutureOr<int> x) => x.abs();
    ''',
        errors: [StaticTypeWarningCode.UNDEFINED_METHOD]);
    _isDynamic(invoke.staticType);
  }

  test_futureOr_methods3() async {
    // Test that FutureOr does not have the Future type methods
    MethodInvocation invoke = await _testFutureOr(
        r'''
    dynamic test(FutureOr<int> x) => x.then((x) => x);
    ''',
        errors: [StaticTypeWarningCode.UNDEFINED_METHOD]);
    _isDynamic(invoke.staticType);
  }

  test_futureOr_methods4() async {
    // Test that FutureOr<dynamic> does not have all methods
    MethodInvocation invoke = await _testFutureOr(
        r'''
    dynamic test(FutureOr<dynamic> x) => x.abs();
    ''',
        errors: [StaticTypeWarningCode.UNDEFINED_METHOD]);
    _isDynamic(invoke.staticType);
  }

  test_futureOr_no_return() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then((int x) {});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOr_no_return_value() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then((int x) {return;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOr_return_null() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then((int x) {return null;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOr_upwards1() async {
    // Test that upwards inference correctly prefers to instantiate type
    // variables with the "smaller" solution when both are possible.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    dynamic test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_upwards2() async {
    // Test that upwards inference fails when the solution doesn't
    // match the bound.
    MethodInvocation invoke = await _testFutureOr(
        r'''
    Future<T> mk<T extends Future<Object>>(FutureOr<T> x) => null;
    dynamic test() => mk(new Future<int>.value(42));
    ''',
        errors: [StrongModeCode.COULD_NOT_INFER]);
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOrNull_no_return() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then<Null>((int x) {});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOrNull_no_return_value() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then<Null>((int x) {return;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOrNull_return_null() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then<Null>((int x) { return null;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_inferConstructor_unknownTypeLowerBound() async {
    Source source = addSource(r'''
        class C<T> {
          C(void callback(List<T> a));
        }
        test() {
          // downwards inference pushes List<?> and in parameter position this
          // becomes inferred as List<Null>.
          var c = new C((items) {});
        }
        ''');
    CompilationUnit unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);
    verify([source]);
    DartType cType = AstFinder
        .getTopLevelFunction(unit, "test")
        .element
        .localVariables[0]
        .type;
    Element elementC = AstFinder.getClass(unit, "C").element;

    _isInstantiationOf(_hasElement(elementC))([_isDynamic])(cType);
  }

  test_inference_hints() async {
    Source source = addSource(r'''
      void main () {
        var x = 3;
        List<int> l0 = [];
     }
   ''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inferredFieldDeclaration_propagation() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25546
    String code = r'''
      abstract class A {
        Map<int, List<int>> get map;
      }
      class B extends A {
        var map = { 42: [] };
      }
      class C extends A {
        get map => { 43: [] };
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);
    Asserter<InterfaceType> assertMapOfIntToListOfInt =
        _isMapOf(_isInt, (DartType type) => assertListOfInt(type));

    VariableDeclaration mapB = AstFinder.getFieldInClass(unit, "B", "map");
    MethodDeclaration mapC = AstFinder.getMethodInClass(unit, "C", "map");
    assertMapOfIntToListOfInt(
        resolutionMap.elementDeclaredByVariableDeclaration(mapB).type);
    assertMapOfIntToListOfInt(
        resolutionMap.elementDeclaredByMethodDeclaration(mapC).returnType);

    MapLiteral mapLiteralB = mapB.initializer;
    MapLiteral mapLiteralC = (mapC.body as ExpressionFunctionBody).expression;
    assertMapOfIntToListOfInt(mapLiteralB.staticType);
    assertMapOfIntToListOfInt(mapLiteralC.staticType);

    ListLiteral listLiteralB = mapLiteralB.entries[0].value;
    ListLiteral listLiteralC = mapLiteralC.entries[0].value;
    assertListOfInt(listLiteralB.staticType);
    assertListOfInt(listLiteralC.staticType);
  }

  test_instanceCreation() async {
    String code = r'''
      class A<S, T> {
        S x;
        T y;
        A(this.x, this.y);
        A.named(this.x, this.y);
      }

      class B<S, T> extends A<T, S> {
        B(S y, T x) : super(x, y);
        B.named(S y, T x) : super.named(x, y);
      }

      class C<S> extends B<S, S> {
        C(S a) : super(a, a);
        C.named(S a) : super.named(a, a);
      }

      class D<S, T> extends B<T, int> {
        D(T a) : super(a, 3);
        D.named(T a) : super.named(a, 3);
      }

      class E<S, T> extends A<C<S>, T> {
        E(T a) : super(null, a);
      }

      class F<S, T> extends A<S, T> {
        F(S x, T y, {List<S> a, List<T> b}) : super(x, y);
        F.named(S x, T y, [S a, T b]) : super(a, b);
      }

      void test0() {
        A<int, String> a0 = new A(3, "hello");
        A<int, String> a1 = new A.named(3, "hello");
        A<int, String> a2 = new A<int, String>(3, "hello");
        A<int, String> a3 = new A<int, String>.named(3, "hello");
        A<int, String> a4 = new A<int, dynamic>(3, "hello");
        A<int, String> a5 = new A<dynamic, dynamic>.named(3, "hello");
      }
      void test1()  {
        A<int, String> a0 = new A("hello", 3);
        A<int, String> a1 = new A.named("hello", 3);
      }
      void test2() {
        A<int, String> a0 = new B("hello", 3);
        A<int, String> a1 = new B.named("hello", 3);
        A<int, String> a2 = new B<String, int>("hello", 3);
        A<int, String> a3 = new B<String, int>.named("hello", 3);
        A<int, String> a4 = new B<String, dynamic>("hello", 3);
        A<int, String> a5 = new B<dynamic, dynamic>.named("hello", 3);
      }
      void test3() {
        A<int, String> a0 = new B(3, "hello");
        A<int, String> a1 = new B.named(3, "hello");
      }
      void test4() {
        A<int, int> a0 = new C(3);
        A<int, int> a1 = new C.named(3);
        A<int, int> a2 = new C<int>(3);
        A<int, int> a3 = new C<int>.named(3);
        A<int, int> a4 = new C<dynamic>(3);
        A<int, int> a5 = new C<dynamic>.named(3);
      }
      void test5() {
        A<int, int> a0 = new C("hello");
        A<int, int> a1 = new C.named("hello");
      }
      void test6()  {
        A<int, String> a0 = new D("hello");
        A<int, String> a1 = new D.named("hello");
        A<int, String> a2 = new D<int, String>("hello");
        A<int, String> a3 = new D<String, String>.named("hello");
        A<int, String> a4 = new D<num, dynamic>("hello");
        A<int, String> a5 = new D<dynamic, dynamic>.named("hello");
      }
      void test7() {
        A<int, String> a0 = new D(3);
        A<int, String> a1 = new D.named(3);
      }
      void test8() {
        A<C<int>, String> a0 = new E("hello");
      }
      void test9() { // Check named and optional arguments
        A<int, String> a0 = new F(3, "hello", a: [3], b: ["hello"]);
        A<int, String> a1 = new F(3, "hello", a: ["hello"], b:[3]);
        A<int, String> a2 = new F.named(3, "hello", 3, "hello");
        A<int, String> a3 = new F.named(3, "hello");
        A<int, String> a4 = new F.named(3, "hello", "hello", 3);
        A<int, String> a5 = new F.named(3, "hello", "hello");
      }
    }''';
    CompilationUnit unit = await resolveSource(code);

    Expression rhs(VariableDeclarationStatement stmt) {
      VariableDeclaration decl = stmt.variables.variables[0];
      Expression exp = decl.initializer;
      return exp;
    }

    void hasType(Asserter<DartType> assertion, Expression exp) =>
        assertion(exp.staticType);

    Element elementA = AstFinder.getClass(unit, "A").element;
    Element elementB = AstFinder.getClass(unit, "B").element;
    Element elementC = AstFinder.getClass(unit, "C").element;
    Element elementD = AstFinder.getClass(unit, "D").element;
    Element elementE = AstFinder.getClass(unit, "E").element;
    Element elementF = AstFinder.getClass(unit, "F").element;

    AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf =
        _isInstantiationOf(_hasElement(elementA));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf =
        _isInstantiationOf(_hasElement(elementB));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertCOf =
        _isInstantiationOf(_hasElement(elementC));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertDOf =
        _isInstantiationOf(_hasElement(elementD));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf =
        _isInstantiationOf(_hasElement(elementE));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertFOf =
        _isInstantiationOf(_hasElement(elementF));

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test0");

      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[1]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[3]));
      hasType(assertAOf([_isInt, _isDynamic]), rhs(statements[4]));
      hasType(assertAOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test1");
      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test2");
      hasType(assertBOf([_isString, _isInt]), rhs(statements[0]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[1]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[2]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[3]));
      hasType(assertBOf([_isString, _isDynamic]), rhs(statements[4]));
      hasType(assertBOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test3");
      hasType(assertBOf([_isString, _isInt]), rhs(statements[0]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[1]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test4");
      hasType(assertCOf([_isInt]), rhs(statements[0]));
      hasType(assertCOf([_isInt]), rhs(statements[1]));
      hasType(assertCOf([_isInt]), rhs(statements[2]));
      hasType(assertCOf([_isInt]), rhs(statements[3]));
      hasType(assertCOf([_isDynamic]), rhs(statements[4]));
      hasType(assertCOf([_isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test5");
      hasType(assertCOf([_isInt]), rhs(statements[0]));
      hasType(assertCOf([_isInt]), rhs(statements[1]));
    }

    {
      // The first type parameter is not constrained by the
      // context.  We could choose a tighter type, but currently
      // we just use dynamic.
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test6");
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[0]));
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[1]));
      hasType(assertDOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertDOf([_isString, _isString]), rhs(statements[3]));
      hasType(assertDOf([_isNum, _isDynamic]), rhs(statements[4]));
      hasType(assertDOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test7");
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[0]));
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test8");
      hasType(assertEOf([_isInt, _isString]), rhs(statements[0]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test9");
      hasType(assertFOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[1]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[3]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[4]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[5]));
    }
  }

  test_listLiteral_nested() async {
    String code = r'''
      void main () {
        List<List<int>> l0 = [[]];
        Iterable<List<int>> l1 = [[3]];
        Iterable<List<int>> l2 = [[3], [4]];
        List<List<int>> l3 = [["hello", 3], []];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    ListLiteral literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);
    Asserter<InterfaceType> assertListOfListOfInt =
        _isListOf((DartType type) => assertListOfInt(type));

    assertListOfListOfInt(literal(0).staticType);
    assertListOfListOfInt(literal(1).staticType);
    assertListOfListOfInt(literal(2).staticType);
    assertListOfListOfInt(literal(3).staticType);

    assertListOfInt(literal(1).elements[0].staticType);
    assertListOfInt(literal(2).elements[0].staticType);
    assertListOfInt(literal(3).elements[0].staticType);
  }

  test_listLiteral_simple() async {
    String code = r'''
      void main () {
        List<int> l0 = [];
        List<int> l1 = [3];
        List<int> l2 = ["hello"];
        List<int> l3 = ["hello", 3];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  test_listLiteral_simple_const() async {
    String code = r'''
      void main () {
        const List<int> c0 = const [];
        const List<int> c1 = const [3];
        const List<int> c2 = const ["hello"];
        const List<int> c3 = const ["hello", 3];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  test_listLiteral_simple_disabled() async {
    String code = r'''
      void main () {
        List<int> l0 = <num>[];
        List<int> l1 = <num>[3];
        List<int> l2 = <String>["hello"];
        List<int> l3 = <dynamic>["hello", 3];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    _isListOf(_isNum)(literal(0));
    _isListOf(_isNum)(literal(1));
    _isListOf(_isString)(literal(2));
    _isListOf(_isDynamic)(literal(3));
  }

  test_listLiteral_simple_subtype() async {
    String code = r'''
      void main () {
        Iterable<int> l0 = [];
        Iterable<int> l1 = [3];
        Iterable<int> l2 = ["hello"];
        Iterable<int> l3 = ["hello", 3];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  test_mapLiteral_nested() async {
    String code = r'''
      void main () {
        Map<int, List<String>> l0 = {};
        Map<int, List<String>> l1 = {3: ["hello"]};
        Map<int, List<String>> l2 = {"hello": ["hello"]};
        Map<int, List<String>> l3 = {3: [3]};
        Map<int, List<String>> l4 = {3:["hello"], "hello": [3]};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    MapLiteral literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      MapLiteral exp = decl.initializer;
      return exp;
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    Asserter<InterfaceType> assertMapOfIntToListOfString =
        _isMapOf(_isInt, (DartType type) => assertListOfString(type));

    assertMapOfIntToListOfString(literal(0).staticType);
    assertMapOfIntToListOfString(literal(1).staticType);
    assertMapOfIntToListOfString(literal(2).staticType);
    assertMapOfIntToListOfString(literal(3).staticType);
    assertMapOfIntToListOfString(literal(4).staticType);

    assertListOfString(literal(1).entries[0].value.staticType);
    assertListOfString(literal(2).entries[0].value.staticType);
    assertListOfString(literal(3).entries[0].value.staticType);
    assertListOfString(literal(4).entries[0].value.staticType);
  }

  test_mapLiteral_simple() async {
    String code = r'''
      void main () {
        Map<int, String> l0 = {};
        Map<int, String> l1 = {3: "hello"};
        Map<int, String> l2 = {"hello": "hello"};
        Map<int, String> l3 = {3: 3};
        Map<int, String> l4 = {3:"hello", "hello": 3};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      MapLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertMapOfIntToString =
        _isMapOf(_isInt, _isString);

    assertMapOfIntToString(literal(0));
    assertMapOfIntToString(literal(1));
    assertMapOfIntToString(literal(2));
    assertMapOfIntToString(literal(3));
  }

  test_mapLiteral_simple_disabled() async {
    String code = r'''
      void main () {
        Map<int, String> l0 = <int, dynamic>{};
        Map<int, String> l1 = <int, dynamic>{3: "hello"};
        Map<int, String> l2 = <int, dynamic>{"hello": "hello"};
        Map<int, String> l3 = <int, dynamic>{3: 3};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      MapLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertMapOfIntToDynamic =
        _isMapOf(_isInt, _isDynamic);

    assertMapOfIntToDynamic(literal(0));
    assertMapOfIntToDynamic(literal(1));
    assertMapOfIntToDynamic(literal(2));
    assertMapOfIntToDynamic(literal(3));
  }

  test_methodDeclaration_body_propagation() async {
    String code = r'''
      class A {
        List<String> m0(int x) => ["hello"];
        List<String> m1(int x) {return [3];};
      }
   ''';
    CompilationUnit unit = await resolveSource(code);
    Expression methodReturnValue(String methodName) {
      MethodDeclaration method =
          AstFinder.getMethodInClass(unit, "A", methodName);
      FunctionBody body = method.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression;
      }
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    assertListOfString(methodReturnValue("m0").staticType);
    assertListOfString(methodReturnValue("m1").staticType);
  }

  test_partialTypes1() async {
    // Test that downwards inference with a partial type
    // correctly uses the partial information to fill in subterm
    // types
    String code = r'''
    typedef To Func1<From, To>(From x);
    S f<S, T>(Func1<S, T> g) => null;
    String test() => f((l) => l.length);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    _isString(body.expression.staticType);
    MethodInvocation invoke = body.expression;
    FunctionExpression function = invoke.argumentList.arguments[0];
    ExecutableElement f0 = function.element;
    FunctionType type = f0.type;
    _isFunction2Of(_isString, _isInt)(type);
  }

  test_pinning_multipleConstraints1() async {
    // Test that downwards inference with two different downwards covariant
    // constraints on the same parameter correctly fails to infer when
    // the types do not share a common subtype
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> { B(S s); }
    A<int, String> test() => new B(3);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertErrors(source,[StrongModeCode.INVALID_CAST_LITERAL]);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    DartType type = body.expression.staticType;

    Element elementB = AstFinder.getClass(unit, "B").element;

    _isInstantiationOf(_hasElement(elementB))([_isNull])(type);
  }

  test_pinning_multipleConstraints2() async {
    // Test that downwards inference with two identical downwards covariant
    // constraints on the same parameter correctly infers and pins the type
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> { B(S s); }
    A<num, num> test() => new B(3);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    DartType type = body.expression.staticType;

    Element elementB = AstFinder.getClass(unit, "B").element;

    _isInstantiationOf(_hasElement(elementB))([_isNum])(type);
  }

  test_pinning_multipleConstraints3() async {
    // Test that downwards inference with two different downwards covariant
    // constraints on the same parameter correctly fails to infer when
    // the types do not share a common subtype, but do share a common supertype
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> { B(S s); }
    A<int, double> test() => new B(3);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertErrors(source, [
      StrongModeCode.INVALID_CAST_LITERAL,
    ]);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    DartType type = body.expression.staticType;

    Element elementB = AstFinder.getClass(unit, "B").element;

    _isInstantiationOf(_hasElement(elementB))([_isNull])(type);
  }

  test_pinning_multipleConstraints4() async {
    // Test that downwards inference with two subtype related downwards
    // covariant constraints on the same parameter correctly infers and pins
    // the type
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    A<int, num> test() => new B();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    DartType type = body.expression.staticType;

    Element elementB = AstFinder.getClass(unit, "B").element;

    _isInstantiationOf(_hasElement(elementB))([_isInt])(type);
  }

  test_pinning_multipleConstraints_contravariant1() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter chooses the upper bound
    // when the only supertype is Object
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, String>> test() => mkA();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").element;

    _isInstantiationOf(_hasElement(elementA))([_isObject, _isObject])(type);
  }

  test_pinning_multipleConstraints_contravariant2() async {
    // Test that downwards inference with two identical downwards contravariant
    // constraints on the same parameter correctly pins the type
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<num, num>> test() => mkA();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").element;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_pinning_multipleConstraints_contravariant3() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter correctly choose the least upper bound
    // when they share a common supertype
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, double>> test() => mkA();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").element;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_pinning_multipleConstraints_contravariant4() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter correctly choose the least upper bound
    // when one is a subtype of the other
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, num>> test() => mkA();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").element;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_redirectingConstructor_propagation() async {
    String code = r'''
      class A {
        A() : this.named([]);
        A.named(List<String> x);
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    RedirectingConstructorInvocation invocation = constructor.initializers[0];
    Expression exp = invocation.argumentList.arguments[0];
    _isListOf(_isString)(exp.staticType);
  }

  test_returnType_variance1() async {
    // Check that downwards inference correctly pins a type parameter
    // when the parameter is constrained in a contravariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x) => null;
    Func1<num, String> test() => f(42);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    MethodInvocation invoke = body.expression;
    _isFunction2Of(_isNum, _isFunction2Of(_isNum, _isString))(
        invoke.staticInvokeType);
  }

  test_returnType_variance2() async {
    // Check that downwards inference correctly pins a type parameter
    // when the parameter is constrained in a covariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x) => null;
    Func1<String, num> test() => f(42);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    MethodInvocation invoke = body.expression;
    _isFunction2Of(_isNum, _isFunction2Of(_isString, _isNum))(
        invoke.staticInvokeType);
  }

  test_returnType_variance3() async {
    // Check that the variance heuristic chooses the most precise type
    // when the return type uses the variable in a contravariant position
    // and there is no downwards constraint.
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x, g(T x)) => null;
    dynamic test() => f(42, (num x) => x);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];
    _isInt(type);
  }

  test_returnType_variance4() async {
    // Check that the variance heuristic chooses the more precise type
    // when the return type uses the variable in a covariant position
    // and there is no downwards constraint
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x, g(T x)) => null;
    dynamic test() => f(42, (num x) => x);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.returnType;
    _isInt(type);
  }

  test_returnType_variance5() async {
    // Check that pinning works correctly with a partial type
    // when the return type uses the variable in a contravariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x) => null;
    T g<T, S>(Func1<T, S> f) => null;
    num test() => g(f(3));
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    MethodInvocation call = body.expression;
    _isNum(call.staticType);
    _isFunction2Of(_isFunction2Of(_isNum, _isString), _isNum)(
        call.staticInvokeType);
  }

  test_returnType_variance6() async {
    // Check that pinning works correctly with a partial type
    // when the return type uses the variable in a covariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x) => null;
    T g<T, S>(Func1<S, T> f) => null;
    num test() => g(f(3));
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    MethodInvocation call = body.expression;
    _isNum(call.staticType);
    _isFunction2Of(_isFunction2Of(_isString, _isNum), _isNum)(
        call.staticInvokeType);
  }

  test_superConstructorInvocation_propagation() async {
    String code = r'''
      class B {
        B(List<String>);
      }
      class A extends B {
        A() : super([]);
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    SuperConstructorInvocation invocation = constructor.initializers[0];
    Expression exp = invocation.argumentList.arguments[0];
    _isListOf(_isString)(exp.staticType);
  }

  test_sync_star_method_propagation() async {
    String code = r'''
      import "dart:async";
      class A {
        Iterable f0() sync* { yield []; }
        Iterable f1() sync* { yield* new List(); }

        Iterable<List<int>> f2() sync* { yield []; }
        Iterable<List<int>> f3() sync* { yield* new List(); }
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      BlockFunctionBody body = test.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("f0", _isListOf(_isDynamic));
    check("f1", _isListOf(_isDynamic));

    check("f2", _isListOf(_isInt));
    check("f3", _isListOf((DartType type) => _isListOf(_isInt)(type)));
  }

  test_sync_star_propagation() async {
    String code = r'''
      import "dart:async";

      Iterable f0() sync* { yield []; }
      Iterable f1() sync* { yield* new List(); }

      Iterable<List<int>> f2() sync* { yield []; }
      Iterable<List<int>> f3() sync* { yield* new List(); }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      BlockFunctionBody body = test.functionExpression.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("f0", _isListOf(_isDynamic));
    check("f1", _isListOf(_isDynamic));

    check("f2", _isListOf(_isInt));
    check("f3", _isListOf((DartType type) => _isListOf(_isInt)(type)));
  }

  /// Helper method for testing `FutureOr<T>`.
  ///
  /// Validates that [code] produces [errors]. It should define a function
  /// "test", whose body is an expression that invokes a method. Returns that
  /// invocation.
  Future<MethodInvocation> _testFutureOr(String code,
      {List<ErrorCode> errors}) async {
    Source source = addSource("""
    import "dart:async";
    $code""");
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);

    if (errors == null) {
      assertNoErrors(source);
    } else {
      assertErrors(source, errors);
    }
    verify([source]);
    FunctionDeclaration test =
        AstFinder.getTopLevelFunction(analysisResult.unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    return body.expression;
  }
}

/**
 * Strong mode static analyzer end to end tests
 */
@reflectiveTest
class StrongModeStaticTypeAnalyzer2Test extends StaticTypeAnalyzer2TestShared {
  void expectStaticInvokeType(String search, String type) {
    var invocation = findIdentifier(search).parent as MethodInvocation;
    expect(invocation.staticInvokeType.toString(), type);
  }

  fail_futureOr_promotion4() async {
    // Test that promotion from FutureOr<T> to T works for type
    // parameters T
    // TODO(leafp): When the restriction on is checks for generic methods
    // goes away this should pass.
    String code = r'''
    import "dart:async";
    dynamic test<T extends num>(FutureOr<T> x) => (x is T) &&
                                                  (x.abs() == 0);
   ''';
    await resolveTestUnit(code);
  }

  fail_genericMethod_tearoff_instantiated() async {
    await resolveTestUnit(r'''
class C<E> {
  /*=T*/ f/*<T>*/(E e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;
  var methodTearOffInst = c.f/*<int>*/;
  var staticTearOffInst = C.g/*<int>*/;
  var staticFieldTearOffInst = C.h/*<int>*/;
  var topFunTearOffInst = topF/*<int>*/;
  var topFieldTearOffInst = topG/*<int>*/;
  var localTearOffInst = lf/*<int>*/;
  var paramTearOffInst = pf/*<int>*/;
}
''');
    expectIdentifierType('methodTearOffInst', "(int) → int");
    expectIdentifierType('staticTearOffInst', "(int) → int");
    expectIdentifierType('staticFieldTearOffInst', "(int) → int");
    expectIdentifierType('topFunTearOffInst', "(int) → int");
    expectIdentifierType('topFieldTearOffInst', "(int) → int");
    expectIdentifierType('localTearOffInst', "(int) → int");
    expectIdentifierType('paramTearOffInst', "(int) → int");
  }

  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongMode = true;
    resetWith(options: options);
  }

  test_dynamicObjectGetter_hashCode() async {
    String code = r'''
main() {
  dynamic a = null;
  var foo = a.hashCode;
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'int', isNull);
  }

  test_dynamicObjectMethod_toString() async {
    String code = r'''
main() {
  dynamic a = null;
  var foo = a.toString();
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'String', isNull);
  }

  test_futureOr_promotion1() async {
    // Test that promotion from FutureOr<T> to T works for concrete types
    String code = r'''
    import "dart:async";
    dynamic test(FutureOr<int> x) => (x is int) && (x.abs() == 0);
   ''';
    await resolveTestUnit(code);
  }

  test_futureOr_promotion2() async {
    // Test that promotion from FutureOr<T> to Future<T> works for concrete
    // types
    String code = r'''
    import "dart:async";
    dynamic test(FutureOr<int> x) => (x is Future<int>) &&
                                     (x.then((x) => x) == null);
   ''';
    await resolveTestUnit(code);
  }

  test_futureOr_promotion4() async {
    // Test that promotion from FutureOr<T> to Future<T> works for type
    // parameters T
    String code = r'''
    import "dart:async";
    dynamic test<T extends num>(FutureOr<T> x) => (x is Future<T>) &&
                                                  (x.then((x) => x) == null);
   ''';
    await resolveTestUnit(code);
  }

  test_genericFunction() async {
    await resolveTestUnit(r'/*=T*/ f/*<T>*/(/*=T*/ x) => null;');
    expectFunctionType('f', '<T>(T) → T',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f = findIdentifier('f');
    FunctionElementImpl e = f.staticElement;
    FunctionType ft = e.type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), '(String) → String');
  }

  test_genericFunction_bounds() async {
    await resolveTestUnit(r'/*=T*/ f/*<T extends num>*/(/*=T*/ x) => null;');
    expectFunctionType('f', '<T extends num>(T) → T',
        elementTypeParams: '[T extends num]', typeFormals: '[T extends num]');
  }

  test_genericFunction_parameter() async {
    await resolveTestUnit(
        r'''
void g(/*=T*/ f/*<T>*/(/*=T*/ x)) {}
''',
        noErrors: false // TODO(paulberry): remove when dartbug.com/28515 fixed.
        );
    expectFunctionType('f', '<T>(T) → T',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f = findIdentifier('f');
    ParameterElementImpl e = f.staticElement;
    FunctionType type = e.type;
    FunctionType ft = type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), '(String) → String');
  }

  test_genericFunction_static() async {
    await resolveTestUnit(r'''
class C<E> {
  static /*=T*/ f/*<T>*/(/*=T*/ x) => null;
}
''');
    expectFunctionType('f', '<T>(T) → T',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f = findIdentifier('f');
    MethodElementImpl e = f.staticElement;
    FunctionType ft = e.type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), '(String) → String');
  }

  test_genericFunction_typedef() async {
    String code = r'''
typedef T F<T>(T x);
F f0;

class C {
  static F f1;
  F f2;
  void g(F f3) {
    F f4;
    f0(3);
    f1(3);
    f2(3);
    f3(3);
    f4(3);
  }
}

class D<S> {
  static F f1;
  F f2;
  void g(F f3) {
    F f4;
    f0(3);
    f1(3);
    f2(3);
    f3(3);
    f4(3);
  }
}
''';
    await resolveTestUnit(code);

    checkBody(String className) {
      List<Statement> statements =
          AstFinder.getStatementsInMethod(testUnit, className, "g");

      for (int i = 1; i <= 5; i++) {
        Expression exp = (statements[i] as ExpressionStatement).expression;
        expect(exp.staticType, typeProvider.dynamicType);
      }
    }

    checkBody("C");
    checkBody("D");
  }

  test_genericFunction_upwardsAndDownwards() async {
    // Regression tests for https://github.com/dart-lang/sdk/issues/27586.
    await resolveTestUnit(r'List<num> x = [1, 2];');
    expectInitializerType('x', 'List<num>');
  }

  test_genericFunction_upwardsAndDownwards_Object() async {
    // Regression tests for https://github.com/dart-lang/sdk/issues/27625.
    await resolveTestUnit(r'''
List<Object> aaa = [];
List<Object> bbb = [1, 2, 3];
List<Object> ccc = [null];
List<Object> ddd = [1 as dynamic];
List<Object> eee = [new Object()];
    ''');
    expectInitializerType('aaa', 'List<Object>');
    expectInitializerType('bbb', 'List<Object>');
    expectInitializerType('ccc', 'List<Object>');
    expectInitializerType('ddd', 'List<Object>');
    expectInitializerType('eee', 'List<Object>');
  }

  test_genericMethod() async {
    await resolveTestUnit(r'''
class C<E> {
  List/*<T>*/ f/*<T>*/(E e) => null;
}
main() {
  C<String> cOfString;
}
''');
    expectFunctionType('f', '<T>(E) → List<T>',
        elementTypeParams: '[T]',
        typeParams: '[E]',
        typeArgs: '[E]',
        typeFormals: '[T]');
    SimpleIdentifier c = findIdentifier('cOfString');
    FunctionType ft = (c.staticType as InterfaceType).getMethod('f').type;
    expect(ft.toString(), '<T>(String) → List<T>');
    ft = ft.instantiate([typeProvider.intType]);
    expect(ft.toString(), '(String) → List<int>');
    expect('${ft.typeArguments}/${ft.typeParameters}', '[String, int]/[E, T]');
  }

  test_genericMethod_explicitTypeParams() async {
    await resolveTestUnit(r'''
class C<E> {
  List/*<T>*/ f/*<T>*/(E e) => null;
}
main() {
  C<String> cOfString;
  var x = cOfString.f/*<int>*/('hi');
}
''');
    MethodInvocation f = findIdentifier('f/*<int>*/').parent;
    FunctionType ft = f.staticInvokeType;
    expect(ft.toString(), '(String) → List<int>');
    expect('${ft.typeArguments}/${ft.typeParameters}', '[String, int]/[E, T]');

    SimpleIdentifier x = findIdentifier('x');
    expect(x.staticType,
        typeProvider.listType.instantiate([typeProvider.intType]));
  }

  test_genericMethod_functionExpressionInvocation_explicit() async {
    await resolveTestUnit(
        r'''
class C<E> {
  /*=T*/ f/*<T>*/(/*=T*/ e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;

  var lambdaCall = (/*<E>*/(/*=E*/ e) => e)/*<int>*/(3);
  var methodCall = (c.f)/*<int>*/(3);
  var staticCall = (C.g)/*<int>*/(3);
  var staticFieldCall = (C.h)/*<int>*/(3);
  var topFunCall = (topF)/*<int>*/(3);
  var topFieldCall = (topG)/*<int>*/(3);
  var localCall = (lf)/*<int>*/(3);
  var paramCall = (pf)/*<int>*/(3);
}
''',
        noErrors: false // TODO(paulberry): remove when dartbug.com/28515 fixed.
        );
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
    expectIdentifierType('lambdaCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_inferred() async {
    await resolveTestUnit(
        r'''
class C<E> {
  /*=T*/ f/*<T>*/(/*=T*/ e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;

  var lambdaCall = (/*<E>*/(/*=E*/ e) => e)(3);
  var methodCall = (c.f)(3);
  var staticCall = (C.g)(3);
  var staticFieldCall = (C.h)(3);
  var topFunCall = (topF)(3);
  var topFieldCall = (topG)(3);
  var localCall = (lf)(3);
  var paramCall = (pf)(3);
}
''',
        noErrors: false // TODO(paulberry): remove when dartbug.com/28515 fixed.
        );
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
    expectIdentifierType('lambdaCall', "int");
  }

  test_genericMethod_functionInvocation_explicit() async {
    await resolveTestUnit(
        r'''
class C<E> {
  /*=T*/ f/*<T>*/(/*=T*/ e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;
  var methodCall = c.f/*<int>*/(3);
  var staticCall = C.g/*<int>*/(3);
  var staticFieldCall = C.h/*<int>*/(3);
  var topFunCall = topF/*<int>*/(3);
  var topFieldCall = topG/*<int>*/(3);
  var localCall = lf/*<int>*/(3);
  var paramCall = pf/*<int>*/(3);
}
''',
        noErrors: false // TODO(paulberry): remove when dartbug.com/28515 fixed.
        );
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
  }

  test_genericMethod_functionInvocation_inferred() async {
    await resolveTestUnit(
        r'''
class C<E> {
  /*=T*/ f/*<T>*/(/*=T*/ e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;
  var methodCall = c.f(3);
  var staticCall = C.g(3);
  var staticFieldCall = C.h(3);
  var topFunCall = topF(3);
  var topFieldCall = topG(3);
  var localCall = lf(3);
  var paramCall = pf(3);
}
''',
        noErrors: false // TODO(paulberry): remove when dartbug.com/28515 fixed.
        );
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
  }

  test_genericMethod_functionTypedParameter() async {
    await resolveTestUnit(r'''
class C<E> {
  List/*<T>*/ f/*<T>*/(/*=T*/ f(E e)) => null;
}
main() {
  C<String> cOfString;
}
''');
    expectFunctionType('f', '<T>((E) → T) → List<T>',
        elementTypeParams: '[T]',
        typeParams: '[E]',
        typeArgs: '[E]',
        typeFormals: '[T]');

    SimpleIdentifier c = findIdentifier('cOfString');
    FunctionType ft = (c.staticType as InterfaceType).getMethod('f').type;
    expect(ft.toString(), '<T>((String) → T) → List<T>');
    ft = ft.instantiate([typeProvider.intType]);
    expect(ft.toString(), '((String) → int) → List<int>');
  }

  test_genericMethod_implicitDynamic() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25100#issuecomment-162047588
    // These should not cause any hints or warnings.
    await resolveTestUnit(r'''
class List<E> {
  /*=T*/ map/*<T>*/(/*=T*/ f(E e)) => null;
}
void foo() {
  List list = null;
  list.map((e) => e);
  list.map((e) => 3);
}''');
    expectIdentifierType('map((e) => e);', '<T>((dynamic) → T) → T', isNull);
    expectIdentifierType('map((e) => 3);', '<T>((dynamic) → T) → T', isNull);

    MethodInvocation m1 = findIdentifier('map((e) => e);').parent;
    expect(m1.staticInvokeType.toString(), '((dynamic) → dynamic) → dynamic');
    MethodInvocation m2 = findIdentifier('map((e) => 3);').parent;
    expect(m2.staticInvokeType.toString(), '((dynamic) → int) → int');
  }

  test_genericMethod_max_doubleDouble() async {
    String code = r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2.0);
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'double', isNull);
  }

  test_genericMethod_max_doubleDouble_prefixed() async {
    String code = r'''
import 'dart:math' as math;
main() {
  var foo = math.max(1.0, 2.0);
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'double', isNull);
  }

  test_genericMethod_max_doubleInt() async {
    String code = r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2);
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'num', isNull);
  }

  test_genericMethod_max_intDouble() async {
    String code = r'''
import 'dart:math';
main() {
  var foo = max(1, 2.0);
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'num', isNull);
  }

  test_genericMethod_max_intInt() async {
    String code = r'''
import 'dart:math';
main() {
  var foo = max(1, 2);
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'int', isNull);
  }

  test_genericMethod_nestedBound() async {
    String code = r'''
class Foo<T extends num> {
  void method/*<U extends T>*/(dynamic/*=U*/ u) {
    u.abs();
  }
}
''';
    // Just validate that there is no warning on the call to `.abs()`.
    await resolveTestUnit(code);
  }

  test_genericMethod_nestedCapture() async {
    await resolveTestUnit(r'''
class C<T> {
  /*=T*/ f/*<S>*/(/*=S*/ x) {
    new C<S>().f/*<int>*/(3);
    new C<S>().f; // tear-off
    return null;
  }
}
''');
    MethodInvocation f = findIdentifier('f/*<int>*/(3);').parent;
    expect(f.staticInvokeType.toString(), '(int) → S');
    FunctionType ft = f.staticInvokeType;
    expect('${ft.typeArguments}/${ft.typeParameters}', '[S, int]/[T, S]');

    expectIdentifierType('f;', '<S₀>(S₀) → S');
  }

  test_genericMethod_nestedFunctions() async {
    await resolveTestUnit(r'''
/*=S*/ f/*<S>*/(/*=S*/ x) {
  g/*<S>*/(/*=S*/ x) => f;
  return null;
}
''');
    expectIdentifierType('f', '<S>(S) → S');
    expectIdentifierType('g', '<S>(S) → <S>(S) → S');
  }

  test_genericMethod_override() async {
    await resolveTestUnit(r'''
class C {
  /*=T*/ f/*<T>*/(/*=T*/ x) => null;
}
class D extends C {
  /*=T*/ f/*<T>*/(/*=T*/ x) => null; // from D
}
''');
    expectFunctionType('f/*<T>*/(/*=T*/ x) => null; // from D', '<T>(T) → T',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f =
        findIdentifier('f/*<T>*/(/*=T*/ x) => null; // from D');
    MethodElementImpl e = f.staticElement;
    FunctionType ft = e.type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), '(String) → String');
  }

  test_genericMethod_override_bounds() async {
    await resolveTestUnit(r'''
class A {}
class B extends A {}
class C {
  /*=T*/ f/*<T extends B>*/(/*=T*/ x) => null;
}
class D extends C {
  /*=T*/ f/*<T extends A>*/(/*=T*/ x) => null;
}
''');
  }

  test_genericMethod_override_covariant_field() async {
    Source source = addSource(r'''
abstract class A {
  num get x;
  set x(covariant num);
}

class B extends A {
  int x;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_genericMethod_override_invalidReturnType() async {
    Source source = addSource(r'''
class C {
  Iterable/*<T>*/ f/*<T>*/(/*=T*/ x) => null;
}
class D extends C {
  String f/*<S>*/(/*=S*/ x) => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.INVALID_METHOD_OVERRIDE]);
    verify([source]);
  }

  test_genericMethod_override_invalidTypeParamBounds() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
class C {
  /*=T*/ f/*<T extends A>*/(/*=T*/ x) => null;
}
class D extends C {
  /*=T*/ f/*<T extends B>*/(/*=T*/ x) => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.INVALID_METHOD_OVERRIDE]);
    verify([source]);
  }

  test_genericMethod_override_invalidTypeParamCount() async {
    Source source = addSource(r'''
class C {
  /*=T*/ f/*<T>*/(/*=T*/ x) => null;
}
class D extends C {
  /*=S*/ f/*<T, S>*/(/*=T*/ x) => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.INVALID_METHOD_OVERRIDE]);
    verify([source]);
  }

  test_genericMethod_propagatedType_promotion() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25340

    // Note, after https://github.com/dart-lang/sdk/issues/25486 the original
    // example won't work, as we now compute a static type and therefore discard
    // the propagated type. So a new test was created that doesn't run under
    // strong mode.
    await resolveTestUnit(r'''
abstract class Iter {
  List/*<S>*/ map/*<S>*/(/*=S*/ f(x));
}
class C {}
C toSpan(dynamic element) {
  if (element is Iter) {
    var y = element.map(toSpan);
  }
  return null;
}''');
    expectIdentifierType('y = ', 'List<C>', isNull);
  }

  test_genericMethod_tearoff() async {
    await resolveTestUnit(
        r'''
class C<E> {
  /*=T*/ f/*<T>*/(E e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;
  var methodTearOff = c.f;
  var staticTearOff = C.g;
  var staticFieldTearOff = C.h;
  var topFunTearOff = topF;
  var topFieldTearOff = topG;
  var localTearOff = lf;
  var paramTearOff = pf;
}
''',
        noErrors: false // TODO(paulberry): remove when dartbug.com/28515 fixed.
        );
    expectIdentifierType('methodTearOff', "<T>(int) → T");
    expectIdentifierType('staticTearOff', "<T>(T) → T");
    expectIdentifierType('staticFieldTearOff', "<T>(T) → T");
    expectIdentifierType('topFunTearOff', "<T>(T) → T");
    expectIdentifierType('topFieldTearOff', "<T>(T) → T");
    expectIdentifierType('localTearOff', "<T>(T) → T");
    expectIdentifierType('paramTearOff', "<T>(T) → T");
  }

  test_genericMethod_then() async {
    String code = r'''
import 'dart:async';
String toString(int x) => x.toString();
main() {
  Future<int> bar = null;
  var foo = bar.then(toString);
}
''';
    await resolveTestUnit(code);

    expectInitializerType('foo', 'Future<String>', isNull);
  }

  test_genericMethod_then_prefixed() async {
    String code = r'''
import 'dart:async' as async;
String toString(int x) => x.toString();
main() {
  async.Future<int> bar = null;
  var foo = bar.then(toString);
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'Future<String>', isNull);
  }

  test_genericMethod_then_propagatedType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25482.
    String code = r'''
import 'dart:async';
void main() {
  Future<String> p;
  var foo = p.then((r) => new Future<String>.value(3));
}
''';
    // This should produce no hints or warnings.
    await resolveTestUnit(code);
    expectInitializerType('foo', 'Future<String>', isNull);
  }

  test_implicitBounds() async {
    String code = r'''
class A<T> {}

class B<T extends num> {}

class C<S extends int, T extends B<S>, U extends A> {}

void test() {
//
  A ai;
  B bi;
  C ci;
  var aa = new A();
  var bb = new B();
  var cc = new C();
}
''';
    await resolveTestUnit(code);
    expectIdentifierType('ai', "A<dynamic>");
    expectIdentifierType('bi', "B<num>");
    expectIdentifierType('ci', "C<int, B<int>, A<dynamic>>");
    expectIdentifierType('aa', "A<dynamic>");
    expectIdentifierType('bb', "B<num>");
    expectIdentifierType('cc', "C<int, B<int>, A<dynamic>>");
  }

  @failingTest
  test_instantiateToBounds_class_error_extension_malbounded() async {
    // Test that superclasses are strictly checked for malbounded default
    // types
    String code = r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
class D extends C {}
''';
    await resolveTestUnit(code, noErrors: false);
    assertErrors(testSource, [StrongModeCode.NO_DEFAULT_BOUNDS]);
  }

  @failingTest
  test_instantiateToBounds_class_error_instantiation_malbounded() async {
    // Test that instance creations are strictly checked for malbounded default
    // types
    String code = r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
void test() {
  var c = new C();
}
''';
    await resolveTestUnit(code, noErrors: false);
    assertErrors(testSource, [StrongModeCode.NO_DEFAULT_BOUNDS]);
    expectIdentifierType('c;', 'C<List<dynamic>, List<dynamic>>');
  }

  test_instantiateToBounds_class_error_recursion() async {
    String code = r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
C c;
''';
    await resolveTestUnit(code, noErrors: false);
    assertNoErrors(testSource);
    expectIdentifierType('c;', 'C<List<dynamic>, List<dynamic>>');
  }

  test_instantiateToBounds_class_error_recursion_self() async {
    String code = r'''
class C<T extends C<T>> {}
C c;
''';
    await resolveTestUnit(code, noErrors: false);
    assertNoErrors(testSource);
    expectIdentifierType('c;', 'C<C<dynamic>>');
  }

  test_instantiateToBounds_class_error_recursion_self2() async {
    String code = r'''
class A<E> {}
class C<T extends A<T>> {}
C c;
''';
    await resolveTestUnit(code, noErrors: false);
    assertNoErrors(testSource);
    expectIdentifierType('c;', 'C<A<dynamic>>');
  }

  test_instantiateToBounds_class_error_typedef() async {
    String code = r'''
typedef T F<T>(T x);
class C<T extends F<T>> {}
C c;
''';
    await resolveTestUnit(code, noErrors: false);
    assertNoErrors(testSource);
    expectIdentifierType('c;', 'C<(dynamic) → dynamic>');
  }

  test_instantiateToBounds_class_ok_implicitDynamic_multi() async {
    String code = r'''
class C<T0 extends Map<T1, T2>, T1 extends List, T2 extends int> {}
C c;
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectIdentifierType(
        'c;', 'C<Map<List<dynamic>, int>, List<dynamic>, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_after() async {
    String code = r'''
class C<T0 extends T1, T1 extends int> {}
C c;
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectIdentifierType('c;', 'C<int, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_after2() async {
    String code = r'''
class C<T0 extends Map<T1, T1>, T1 extends int> {}
C c;
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectIdentifierType('c;', 'C<Map<int, int>, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_before() async {
    String code = r'''
class C<T0 extends int, T1 extends T0> {}
C c;
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectIdentifierType('c;', 'C<int, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_multi() async {
    String code = r'''
class C<T0 extends Map<T1, T2>, T1 extends List<T2>, T2 extends int> {}
C c;
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectIdentifierType('c;', 'C<Map<List<int>, int>, List<int>, int>');
  }

  test_instantiateToBounds_class_ok_simpleBounds() async {
    String code = r'''
class A<T> {}
class B<T extends num> {}
class C<T extends List<int>> {}
class D<T extends A> {}
void main() {
  A a;
  B b;
  C c;
  D d;
}
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectIdentifierType('a;', 'A<dynamic>');
    expectIdentifierType('b;', 'B<num>');
    expectIdentifierType('c;', 'C<List<int>>');
    expectIdentifierType('d;', 'D<A<dynamic>>');
  }

  @failingTest
  test_instantiateToBounds_generic_function_error_malbounded() async {
    // Test that generic methods are strictly checked for malbounded default
    // types
    String code = r'''
T0 f<T0 extends List<T1>, T1 extends List<T0>>() {}
void g() {
  var c = f();
  return;
}
''';
    await resolveTestUnit(code, noErrors: false);
    assertErrors(testSource, [StrongModeCode.NO_DEFAULT_BOUNDS]);
    expectIdentifierType('c;', 'List<dynamic>');
  }

  test_instantiateToBounds_method_ok_referenceOther_before() async {
    String code = r'''
class C<T> {
  void m<S0 extends T, S1 extends List<S0>>(S0 p0, S1 p1) {}

  void main() {
    m(null, null);
  }
}
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectStaticInvokeType('m(null', '(Null, Null) → void');
  }

  test_instantiateToBounds_method_ok_referenceOther_before2() async {
    String code = r'''
class C<T> {
  Map<S0, S1> m<S0 extends T, S1 extends List<S0>>() => null;

  void main() {
    m();
  }
}
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectStaticInvokeType('m();', '() → Map<T, List<T>>');
  }

  test_instantiateToBounds_method_ok_simpleBounds() async {
    String code = r'''
class C<T> {
  void m<S extends T>(S p0) {}

  void main() {
    m(null);
  }
}
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectStaticInvokeType('m(null)', '(Null) → void');
  }

  test_instantiateToBounds_method_ok_simpleBounds2() async {
    String code = r'''
class C<T> {
  S m<S extends T>() => null;

  void main() {
    m();
  }
}
''';
    await resolveTestUnit(code);
    assertNoErrors(testSource);
    expectStaticInvokeType('m();', '() → T');
  }

  test_notInstantiatedBound_direct_class_class() async {
    String code = r'''
class A<T extends int> {}
class C<T extends A> {}
''';
    await resolveTestUnit(code, noErrors: false);
    assertErrors(testSource, [StrongModeCode.NOT_INSTANTIATED_BOUND]);
  }

  test_notInstantiatedBound_direct_class_typedef() async {
    // Check that if the bound of a class is an uninstantiated typedef
    // we emit an error
    String code = r'''
typedef void F<T extends int>();
class C<T extends F> {}
''';
    await resolveTestUnit(code, noErrors: false);
    assertErrors(testSource, [StrongModeCode.NOT_INSTANTIATED_BOUND]);
  }

  test_notInstantiatedBound_direct_typedef_class() async {
    // Check that if the bound of a typeded is an uninstantiated class
    // we emit an error
    String code = r'''
class C<T extends int> {}
typedef void F<T extends C>();
''';
    await resolveTestUnit(code, noErrors: false);
    assertErrors(testSource, [StrongModeCode.NOT_INSTANTIATED_BOUND]);
  }

  test_notInstantiatedBound_indirect_class_class() async {
    String code = r'''
class A<T> {}
class B<T extends int> {}
class C<T extends A<B>> {}
''';
    await resolveTestUnit(code, noErrors: false);
    assertErrors(testSource, [StrongModeCode.NOT_INSTANTIATED_BOUND]);
  }

  test_notInstantiatedBound_indirect_class_class2() async {
    String code = r'''
class A<K, V> {}
class B<T extends int> {}
class C<T extends A<B, B>> {}
''';
    await resolveTestUnit(code, noErrors: false);
    assertErrors(testSource, [
      StrongModeCode.NOT_INSTANTIATED_BOUND,
      StrongModeCode.NOT_INSTANTIATED_BOUND
    ]);
  }

  test_objectMethodOnFunctions_Anonymous() async {
    String code = r'''
void main() {
  var f = (x) => 3;
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}''';
    await _objectMethodOnFunctions_helper2(code);
  }

  test_objectMethodOnFunctions_Function() async {
    String code = r'''
void main() {
  Function f;
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}''';
    await _objectMethodOnFunctions_helper2(code);
  }

  test_objectMethodOnFunctions_Static() async {
    String code = r'''
int f(int x) => null;
void main() {
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}''';
    await _objectMethodOnFunctions_helper2(code);
  }

  test_objectMethodOnFunctions_Typedef() async {
    String code = r'''
typedef bool Predicate<T>(T object);

void main() {
  Predicate<int> f;
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}''';
    await _objectMethodOnFunctions_helper2(code);
  }

  test_setterWithDynamicTypeIsError() async {
    Source source = addSource(r'''
class A {
  dynamic set f(String s) => null;
}
dynamic set g(int x) => null;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.NON_VOID_RETURN_FOR_SETTER,
      StaticWarningCode.NON_VOID_RETURN_FOR_SETTER
    ]);
    verify([source]);
  }

  test_setterWithExplicitVoidType_returningVoid() async {
    Source source = addSource(r'''
void returnsVoid() {}
class A {
  void set f(String s) => returnsVoid();
}
void set g(int x) => returnsVoid();
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_setterWithNoVoidType() async {
    Source source = addSource(r'''
class A {
  set f(String s) {
    return '42';
  }
}
set g(int x) => 42;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticTypeWarningCode.RETURN_OF_INVALID_TYPE,
    ]);
    verify([source]);
  }

  test_setterWithNoVoidType_returningVoid() async {
    Source source = addSource(r'''
void returnsVoid() {}
class A {
  set f(String s) => returnsVoid();
}
set g(int x) => returnsVoid();
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_setterWithOtherTypeIsError() async {
    Source source = addSource(r'''
class A {
  String set f(String s) => null;
}
Object set g(x) => null;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.NON_VOID_RETURN_FOR_SETTER,
      StaticWarningCode.NON_VOID_RETURN_FOR_SETTER
    ]);
    verify([source]);
  }

  test_ternaryOperator_null_left() async {
    String code = r'''
main() {
  var foo = (true) ? null : 3;
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'int', isNull);
  }

  test_ternaryOperator_null_right() async {
    String code = r'''
main() {
  var foo = (true) ? 3 : null;
}
''';
    await resolveTestUnit(code);
    expectInitializerType('foo', 'int', isNull);
  }

  Future<Null> _objectMethodOnFunctions_helper2(String code) async {
    await resolveTestUnit(code);
    expectIdentifierType('t0', "String");
    expectIdentifierType('t1', "() → String");
    expectIdentifierType('t2', "int");
    expectIdentifierType('t3', "String");
    expectIdentifierType('t4', "() → String");
    expectIdentifierType('t5', "int");
  }
}

@reflectiveTest
class StrongModeTypePropagationTest extends ResolverTestCase {
  @override
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongMode = true;
    resetWith(options: options);
  }

  test_foreachInference_dynamic_disabled() async {
    String code = r'''
main() {
  var list = <int>[];
  for (dynamic v in list) {
    v; // marker
  }
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedIterationType(code, unit, typeProvider.dynamicType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.dynamicType, null);
  }

  test_foreachInference_reusedVar_disabled() async {
    String code = r'''
main() {
  var list = <int>[];
  var v;
  for (v in list) {
    v; // marker
  }
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedIterationType(code, unit, typeProvider.dynamicType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.dynamicType, null);
  }

  test_foreachInference_var() async {
    String code = r'''
main() {
  var list = <int>[];
  for (var v in list) {
    v; // marker
  }
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedIterationType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_foreachInference_var_iterable() async {
    String code = r'''
main() {
  Iterable<int> list = <int>[];
  for (var v in list) {
    v; // marker
  }
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedIterationType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_foreachInference_var_stream() async {
    String code = r'''
import 'dart:async';
main() async {
  Stream<int> stream = null;
  await for (var v in stream) {
    v; // marker
  }
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedIterationType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_bottom_disabled() async {
    String code = r'''
main() {
  var v = null;
  v; // marker
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.dynamicType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.dynamicType, null);
  }

  test_localVariableInference_constant() async {
    String code = r'''
main() {
  var v = 3;
  v; // marker
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_declaredType_disabled() async {
    String code = r'''
main() {
  dynamic v = 3;
  v; // marker
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.dynamicType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.dynamicType, null);
  }

  test_localVariableInference_noInitializer_disabled() async {
    String code = r'''
main() {
  var v;
  v = 3;
  v; // marker
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.dynamicType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.dynamicType, null);
  }

  test_localVariableInference_transitive_field_inferred_lexical() async {
    String code = r'''
class A {
  final x = 3;
  f() {
    var v = x;
    return v; // marker
  }
}
main() {
}
''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_transitive_field_inferred_reversed() async {
    String code = r'''
class A {
  f() {
    var v = x;
    return v; // marker
  }
  final x = 3;
}
main() {
}
''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_transitive_field_lexical() async {
    String code = r'''
class A {
  int x = 3;
  f() {
    var v = x;
    return v; // marker
  }
}
main() {
}
''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_transitive_field_reversed() async {
    String code = r'''
class A {
  f() {
    var v = x;
    return v; // marker
  }
  int x = 3;
}
main() {
}
''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_transitive_list_local() async {
    String code = r'''
main() {
  var x = <int>[3];
  var v = x[0];
  v; // marker
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_transitive_local() async {
    String code = r'''
main() {
  var x = 3;
  var v = x;
  v; // marker
}''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_transitive_toplevel_inferred_lexical() async {
    String code = r'''
final x = 3;
main() {
  var v = x;
  v; // marker
}
''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_transitive_toplevel_inferred_reversed() async {
    String code = r'''
main() {
  var v = x;
  v; // marker
}
final x = 3;
''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_transitive_toplevel_lexical() async {
    String code = r'''
int x = 3;
main() {
  var v = x;
  v; // marker
}
''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }

  test_localVariableInference_transitive_toplevel_reversed() async {
    String code = r'''
main() {
  var v = x;
  v; // marker
}
int x = 3;
''';
    CompilationUnit unit = await resolveSource(code);
    assertPropagatedAssignedType(code, unit, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, unit, typeProvider.intType, null);
  }
}
