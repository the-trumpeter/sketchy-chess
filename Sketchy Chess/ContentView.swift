//
//  ContentView.swift
//  Chestest
//
//  Created by Gill Palmer on 30/3/2026.
//

import SwiftUI
import SwiftData
internal import Combine

typealias Colour = Color


class ChessGame: ObservableObject {
    @Published var gameData: [
		UUID: (piece: ChessPiece, player: Player, x: Int, y: Int)
	]

	@AppStorage("chess-game-autoFlipBoard") var autoFlipBoard = true
	@AppStorage("chess-game-enforceTurns") var enforceTurns = false
	@AppStorage("chess-game-whoseTurn") var whoseTurn = Player.white

	init(board: [UUID: (piece: ChessPiece, player: Player, x: Int, y: Int)] = defaultLayout) {
		self.gameData = board
	}

}


//MARK: Base enums
enum Player: String {
	case white, black
	mutating func toggle() {
		switch self {
		case .white: self = .black
		case .black: self = .white
		}
	}
}
enum ChessPiece: String {
	case pawn
	case rook
	case knight
	case bishop
	case queen
	case king
}

// Codable-friendly representation for saving/loading board state (dictionary form)
private struct CodableEntry: Codable {
    let piece: String
    let player: String
    let x: Int
    let y: Int
}

private struct CodableBoard: Codable {
    let entries: [UUID: CodableEntry]
}

//MARK: Subscript board coordinates
extension Dictionary where Key == UUID, Value == (piece: ChessPiece, player: Player, x: Int, y: Int) {

	subscript(_ c: (x: Int, y: Int) ) -> (uuid: UUID, piece: ChessPiece, player: Player)? {

		if let contents = self.first(where: { $1.x == c.x && $1.y == c.y }) {
			let formatted: (uuid: UUID, piece: ChessPiece, player: Player) = (contents.key, contents.value.piece, contents.value.player)
			return formatted
		}
		return nil
	}
}



//MARK: Default Layout
let blankRow: [(ChessPiece, Player)?] = Array(repeating: nil, count: 8)
let defaultLayout: [ UUID: (piece: ChessPiece, player: Player, x: Int, y: Int) ] = [
	UUID(): (.rook, .black, 1, 1), UUID(): (.knight, .black, 2, 1), UUID(): (.bishop, .black, 3, 1), UUID(): (.queen, .black, 4, 1), UUID(): (.king, .black, 5, 1), UUID(): (.bishop, .black, 6, 1), UUID(): (.knight, .black, 7, 1), UUID(): (.rook, .black, 8, 1),
	UUID(): (.pawn, .black, 1, 2), UUID(): (.pawn, .black, 2, 2),   UUID(): (.pawn, .black, 3, 2),   UUID(): (.pawn, .black, 4, 2),  UUID(): (.pawn, .black, 5, 2),  UUID(): (.pawn, .black, 6, 2),   UUID(): (.pawn, .black, 7, 2),   UUID(): (.pawn, .black, 8, 2),

	UUID(): (.pawn, .white, 1, 7), UUID(): (.pawn, .white, 2, 7),   UUID(): (.pawn, .white, 3, 7),   UUID(): (.pawn, .white, 4, 7),   UUID(): (.pawn, .white, 5, 7), UUID(): (.pawn, .white, 6, 7),   UUID(): (.pawn, .white, 7, 7),   UUID(): (.pawn, .white, 8, 7),
	UUID(): (.rook, .white, 1, 8), UUID(): (.knight, .white, 2, 8), UUID():  (.bishop, .white, 3,8), UUID(): (.queen, .white, 4, 8),  UUID(): (.king, .white, 5, 8), UUID(): (.bishop, .white, 6, 8), UUID(): (.knight, .white, 7, 8), UUID(): (.rook, .white, 8, 8)
]






//MARK: Promotion
fileprivate struct PromotionPopover: View {
	@Environment(\.dismiss) var dismiss
	@Binding var isFlipped: Bool

	@ObservedObject var chessGame: ChessGame
	@Binding var selected: (x: Int, y: Int)?
//	@Binding var dottedSel: Bool
	let squareIsDark: Bool

	var save: () -> Void

	let promotablePieces = ["rook", "knight", "bishop", "queen"]

	var body: some View {
		VStack {
			let piece: (uuid: UUID, piece: ChessPiece, player: Player)? = if let s = selected { chessGame.gameData[s] } else { nil }
//			HStack {
//				let pieceName: String? = { if let p = piece { return p.piece.rawValue } else { return nil } }()
//				Rectangle()
//					.fill(squareIsDark ? .dark : .light )
//					.overlay {
//						if let p = pieceName {
//							if piece?.player == .black {
//								Image(p)
//									.resizable()
//									.padding(3)
//									.colorInvert()
//							} else {
//								Image(p)
//									.resizable()
//									.padding(3)
//							}
//						}
//					}
//					.frame(minWidth: 30, minHeight: 30)
//					.aspectRatio(1, contentMode: .fit)
//
//				Spacer()
//			}


			HStack {
				ForEach(promotablePieces, id: \.self) { p in
					Rectangle()
						.fill(squareIsDark ? .dark : .light )
						.overlay {
							if piece?.player == .black {
								Image(p)
									.resizable()
									.padding(3)
									.colorInvert()
							} else {
								Image(p)
									.resizable()
									.padding(3)
							}
						}
						.frame(minWidth: 45, minHeight: 45)
						.aspectRatio(1, contentMode: .fit)
						.onTapGesture {
							//Set piece and dismiss
							if let s = selected, piece != nil {
								let newData = (
									ChessPiece(rawValue: p)!,
									piece!.player,
									s.x, s.y
								)
								withAnimation {
									chessGame.gameData[piece!.uuid] = newData
								}
							}
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
								dismiss()
								withAnimation {
									selected = nil
								}
//								dottedSel = false
							}
							save()
						}
				}
			}
		}
		.rotationEffect(Angle(degrees: isFlipped ? 180 : 0))
	}

}











///MARK: Single square
//fileprivate struct GridBox: View {
//	@Binding var isFlipped: Bool
//
//	var piece: Binding<(piece: ChessPiece, player: Player)?>
//	var isSelected: Binding<Bool>
////	@Binding var dottedSel: Bool
//
//	let /*square*/isDark: Bool
//
//	let selColour = Colour.blue
//
//	var body: some View {
//		let pieceName: String? = { if let p = piece.wrappedValue { return p.piece.rawValue } else { return nil } }()
//		Rectangle()
//			.fill(isDark ? .dark : .light )
//			.strokeBorder(selColour, style: .init(lineWidth: isSelected.wrappedValue ? 3 : 0) )//, dash: dottedSel ? [10,5] : [CGFloat]() ) )
////		, dash: dottedSel ? 2 : 0
//			.overlay {
//				if let p = pieceName {
//					if piece.wrappedValue?.player == .black {
//						Image(p)
//							.resizable()
//							.padding(3)
//							.colorInvert()
//							.rotationEffect(Angle(degrees: isFlipped ? 180 : 0))
//					} else {
//						Image(p)
//							.resizable()
//							.padding(3)
//							.rotationEffect(Angle(degrees: isFlipped ? 180 : 0))
//					}
//				}
//			}
//
//			.padding(-4)
//		//			Text(pieceInitial).foregroundStyle(.white)
//	}
//}



//MARK: Row
fileprivate struct GridRow: View {
//	@Binding var isFlipped: Bool
//
//	@ObservedObject var chessGame: ChessGame
//	@Binding var promoting: (x: Int, y: Int)?
//	@Binding var selected: (x: Int, y: Int)?
////	@Binding var dottedSel: Bool
//
//	@Environment(\.undoManager) var undoManager
//
//
//	var toCodableBoard: (_ board: [[(piece: ChessPiece, player: Player)?]]) -> CodableBoard
//
//	MARK: Save
//	func save() {
//		let codable = toCodableBoard(chessGame.gameData)
//		if let data = try? JSONEncoder().encode(codable) {
//			UserDefaults.standard.set(data, forKey: "chess-data-json")
//		}
//
//		if chessGame.autoFlipBoard {
//			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//				withAnimation {
//					isFlipped.toggle()
//				}
//			}
//		}
//		chessGame.whoseTurn.toggle()
//	}
//
//
//	//MARK: Make a move
//	func changeSel(_ currentValue: (x: Int, y: Int)?, to me: (x: Int, y: Int) ) {
//
//		let myContent = chessGame.gameData[me]
//
//		if let origin = currentValue {
//
//			//tap again to deselect
//			if origin == me {
//				selected = nil
//			} else {
//
//				//this is target square
//
//				//get piece to move
//				guard let originContent = chessGame.gameData[origin] else { selected = nil; return }
//
//				// dont move if to-move is same colour; instead select self (target)
//				if originContent.player == myContent?.player {
//					selected = me
//
//				} else {
//
//					//move origin to self
//					chessGame.gameData[me.y-1][me.x-1] = originContent
//					chessGame.gameData[origin.y-1][origin.x-1] = nil
//
//					//MARK: Register undo
//					undoManager?.registerUndo(withTarget: chessGame) { target in
//
////						selColour = .red
////						withAnimation {
////							selected = (me.x-1, me.y-1)
////						}
//						withAnimation {
//							chessGame.gameData[me.y-1][me.x-1] = myContent
//							chessGame.gameData[origin.y-1][origin.x-1] = originContent
////							selected = nil
////							selColour = .blue
//						}
//						chessGame.whoseTurn.toggle()
//					}
//
////					prevMove = (
////						(origin, originContent),
////						(me, myContent)
////					)
//
//					selected = nil
//
//					if originContent.piece == .pawn {
//						if
//							originContent.player == .white && me.y == 1 ||
//								originContent.player == .black && me.y == 8
//						{
////							selColour = .green
////							dottedSel = true
//							withAnimation {
//								selected = me
//							}
//							promoting = me
//							return
//						}
//					}
//
//					save()
//
//				}
//			}
//
//		} else {
//			if myContent != nil {
//				if chessGame.enforceTurns {
//					guard chessGame.whoseTurn == myContent?.player else { return }
//				}
//				selected = me
//			}
//		}
//
//	}//changeSel


	let yy: Int

	var body: some View {

		ForEach(Array(1...8), id: \.self) { xx in


			let isDark = (xx+yy)%2 != 0

			Rectangle()
				.fill(isDark ? .dark : .light )
//				.strokeBorder(selColour, style: .init(lineWidth: isSelected.wrappedValue ? 3 : 0) )//, dash: dottedSel ? [10,5] : [CGFloat]() ) )
				.padding(-4)


//			let pieceBinding: Binding<(piece: ChessPiece, player: Player)?> = Binding<(piece: ChessPiece, player: Player)?>(
//				get: { chessGame.gameData[(xx, yy)] },
//				set: { newValue in
//					chessGame.gameData[yy-1][xx-1] = newValue
//				}
//			)
//
//			let isSelectedBinding: Binding<Bool> = Binding<Bool>(
//				get: {
//					if let s = selected {
//						return s == (xx, yy)
//					} else {
//						return false
//					}
//				},
//				set: { sel in
//					if sel {
//						selected = (xx, yy)
//					} else {
//						if let s = selected, s == (xx, yy) {
//							selected = nil
//						}
//					}
//				}
//			)
//
//			let popoverPresented: Binding<Bool> = Binding(
//				get: {
//					if let p = promoting {
//						return p == (xx, yy)
//					} else {
//						return false
//					}
//				},
//				set: { new in
//					if new {
//						promoting = (xx, yy)
//					} else {
//						if let p = promoting, p == (xx, yy) {
//							promoting = nil
//						}
//					}
//				}
//			)
//
//			GridBox(
//				isFlipped: $isFlipped,
//				piece: pieceBinding,
//				isSelected: isSelectedBinding,
////				dottedSel: $dottedSel,
//				isDark: isDark
//			)
//
//			.popover(isPresented: popoverPresented) {
//				PromotionPopover(
//					isFlipped: $isFlipped,
//					chessGame: chessGame,
//					selected: $selected,
////					dottedSel: $dottedSel,
//					squareIsDark: isDark,
//					save: save
//				)
//					.padding()
//					.presentationCompactAdaptation(.popover)
//					.interactiveDismissDisabled()
//			}
//
//			.onTapGesture {
//				changeSel(selected, to: (xx,yy))
//			}

		}
	}
}


//MARK: Piece View
struct PieceView: View {

	let elementValue: (piece: ChessPiece, player: Player, x: Int, y: Int)
	@Binding var boardIsFlipped: Bool

	@ObservedObject var chessGame: ChessGame
	@Binding var selected: (x: Int, y: Int)?
	@Binding var promoting: (x: Int, y: Int)?

	@Environment(\.undoManager) var undoManager

	@State var popoverPresented = false

	
	fileprivate var toCodableBoard: ( [UUID : (piece: ChessPiece, player: Player, x: Int, y: Int)] ) -> CodableBoard

	func save() {
		let codable = toCodableBoard(chessGame.gameData)
		if let data = try? JSONEncoder().encode(codable) {
			UserDefaults.standard.set(data, forKey: "chess-data-json")
		}

		if chessGame.autoFlipBoard {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				withAnimation {
					boardIsFlipped.toggle()
				}
			}
		}
		chessGame.whoseTurn.toggle()
	}


	func changeSel() {
		let me = (x: elementValue.x, y: elementValue.y)

		// If nothing selected yet, select this piece if it belongs to the current player when enforcing turns
		if selected == nil {
			if chessGame.enforceTurns && elementValue.player != chessGame.whoseTurn {
				return
			}
			selected = me
			return
		}
		
		guard let origin = selected else { return }

		// If tapping the same square, deselect
		if origin == me {
			selected = nil
			return
		}

		// Find origin piece by coordinates
		guard let originEntry = chessGame.gameData.first(where: { $0.value.x == origin.x && $0.value.y == origin.y }) else {
			selected = nil
			return
		}
		let originUUID = originEntry.key
		let originContent = originEntry.value

		// Find destination piece (if any) by coordinates
		let destEntry = chessGame.gameData.first(where: { $0.value.x == me.x && $0.value.y == me.y })

		// If destination has a piece of the same color, reselect destination instead of moving
		if let destEntry, destEntry.value.player == originContent.player {
			selected = me
			return
		}

		// Register undo: restore origin and destination to their previous states
		let previousDest = destEntry?.value
		undoManager?.registerUndo(withTarget: chessGame) { target in
			if let destEntry {
				target.gameData[destEntry.key] = previousDest
			}
			target.gameData[originUUID] = originContent
			target.whoseTurn.toggle()
			save()
		}

		// Perform move: update origin piece's coordinates to destination, remove captured piece if needed
		var moved = originContent
		moved.x = me.x
		moved.y = me.y
		if let destEntry { chessGame.gameData.removeValue(forKey: destEntry.key) }
		chessGame.gameData[originUUID] = moved

		// Clear selection by default
		selected = nil

		// Handle promotion if a pawn reaches the back rank
		if moved.piece == .pawn && ((moved.player == .white && me.y == 1) || (moved.player == .black && me.y == 8)) {
			selected = me
			promoting = me
		} else {
			save()
		}
	}

	var body: some View {


		ZStack {

			Colour.clear.contentShape(Rectangle())

			if elementValue.player == .black {
				Image(elementValue.piece.rawValue)
					.resizable()
					.padding(3)
					.colorInvert()
					.rotationEffect(Angle(degrees: boardIsFlipped ? 180 : 0))
			} else {
				Image(elementValue.piece.rawValue)
					.resizable()
					.padding(3)
					.rotationEffect(Angle(degrees: boardIsFlipped ? 180 : 0))
			}
		}
		.popover(isPresented: $popoverPresented) {
			let isDark = (elementValue.x + elementValue.y)%2 != 0
			PromotionPopover(
				isFlipped: $boardIsFlipped,
				chessGame: chessGame,
				selected: $selected,
				squareIsDark: isDark,
				save: save
			)
			.padding()
			.presentationCompactAdaptation(.popover)
			.interactiveDismissDisabled()
		}

		.onTapGesture {
			changeSel()
		}


	}
}




//MARK: ContentView
struct ContentView: View {
	@State var boardIsFlipped = false

	@StateObject var chessGame = ChessGame()

	@State var resetConfirmation = false

	@State var selected: (x: Int, y: Int)? = nil
	@State var promoting: (x: Int, y: Int)? = nil
//	@State var dottedSel = false

	@Environment(\.undoManager) var undoManager
//	@State var prevMove: (
//		origin: (
//			coords: (x: Int, y: Int),
//			content: (piece: ChessPiece, player: Player)
//		),
//		to: (
//			coords: (x: Int, y: Int),
//			oldContent: (piece: ChessPiece, player: Player)?
//		)
//	)? = nil
	@State var confirmUndo = false
	@State var confirmRedo = false

	private func fromCodableBoard(_ codable: CodableBoard) -> [UUID: (piece: ChessPiece, player: Player, x: Int, y: Int)] {
		var dict: [UUID: (piece: ChessPiece, player: Player, x: Int, y: Int)] = [:]
		for (uuid, entry) in codable.entries {
			if let piece = ChessPiece(rawValue: entry.piece), let player = Player(rawValue: entry.player) {
				dict[uuid] = (piece: piece, player: player, x: entry.x, y: entry.y)
			}
		}
		return dict
	}
	private func toCodableBoard(_ board: [UUID: (piece: ChessPiece, player: Player, x: Int, y: Int)]) -> CodableBoard {
		var entries: [UUID: CodableEntry] = [:]
		for (uuid, value) in board {
			entries[uuid] = CodableEntry(
				piece: value.piece.rawValue,
				player: value.player.rawValue,
				x: value.x,
				y: value.y
			)
		}
		return CodableBoard(entries: entries)
	}

	var body: some View {
		NavigationStack {
			ZStack {

				//BACKGROUND
				Colour(.systemBackground)
					.ignoresSafeArea()
					.onTapGesture {
						selected = nil
					}

				GeometryReader { geo in
					let boardSide = min(geo.size.width, geo.size.height)
					let squareSize = boardSide / 8.0

					ZStack {
						//BOARD
						VStack {
							ForEach(Array(1...8), id: \.self) { yy in
								HStack { GridRow(yy: yy) }
							}

						}.aspectRatio(1, contentMode: .fit)
						//						.onChange(of: chessGame.enforceTurns) {_, new in
						//							if new == true, let sel = selected {
						//								let data = chessGame.gameData[sel]
						//								if data?.player != chessGame.whoseTurn {
						//									selected = nil
						//								}
						//							}
						//						}


						//PIECES
						let chessGameKeys = Array(chessGame.gameData.keys)
						ForEach(chessGameKeys, id: \.self) { key in
							let element = chessGame.gameData[key]!

							let posXBase = CGFloat(element.x-1) * squareSize
							let posYBase = CGFloat(element.y-1) * squareSize
							PieceView(
								elementValue: element,
								boardIsFlipped: $boardIsFlipped,
								chessGame: chessGame,
								selected: $selected,
								promoting: $promoting,
								toCodableBoard: toCodableBoard
							)
								.frame(width: squareSize, height: squareSize)
								.position(x:
											posXBase + squareSize/2,
										  y:
											posYBase + squareSize/2
								)



						}


					}

				}

			}







			.onAppear {
				if let data = UserDefaults.standard.data(forKey: "chess-data-json") {
					if let decoded = try? JSONDecoder().decode(CodableBoard.self, from: data) {
						chessGame.gameData = fromCodableBoard(decoded)
					}
				}
			}
			.padding()

//			.alert("Redo Move", isPresented: $confirmRedo) {
//				Button("Redo") {
//					withAnimation {
////						if let to = prevMove?.to,
////						   let origin = prevMove?.origin {
////
////							chessGame.gameData[origin.coords.y-1][origin.coords.x-1] = origin.content
////							chessGame.gameData[to.coords.y-1][to.coords.x-1] = to.oldContent
////							prevMove = nil
////							selected = nil
////						}
//						if undoManager?.canRedo ?? false {
//							undoManager?.redo()
//						}
//					}
//				}.tint(.blue)
//				Button("Cancel", role: .cancel) {
//					confirmRedo = false
//				}
//			}

			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button {
						withAnimation {
							boardIsFlipped.toggle()
						}
					} label: {
						Label("Flip Board", systemImage: "arrow.up.arrow.down")
							.rotationEffect(Angle(degrees: boardIsFlipped ? 180 : 0))
					}
				}

				ToolbarItem(placement: .topBarTrailing) {
					Button("Undo", systemImage: "arrow.uturn.backward") {
						confirmUndo = true
					}.disabled(!(undoManager?.canUndo ?? false))//(prevMove==nil)
						.confirmationDialog("Undo Move", isPresented: $confirmUndo) {
							Button("Undo") {
								withAnimation {
			//						if let to = prevMove?.to,
			//						   let origin = prevMove?.origin {
			//
			//							chessGame.gameData[origin.coords.y-1][origin.coords.x-1] = origin.content
			//							chessGame.gameData[to.coords.y-1][to.coords.x-1] = to.oldContent
			//							prevMove = nil
			//							selected = nil
			//						}
									if undoManager?.canUndo ?? false {
										undoManager?.undo()
									}
								}
							}
						} message: { Text("Undo Move") }
				}

				ToolbarItem(placement: .topBarTrailing) {
					Menu("Options", systemImage: "ellipsis") {
						
//						Button("Redo", systemImage: "arrow.uturn.forward") {
//							confirmRedo = true
//						}.disabled(!(undoManager?.canRedo ?? false))

						Toggle("Auto-Flip Board", isOn: $chessGame.autoFlipBoard)

//						let whoseTurnText = switch chessGame.whoseTurn { case .black: "Black"; case .white: "White" }
//						Section("\(whoseTurnText)'s turn") {
//							Toggle("Enforce Turns (works badly)", isOn: $chessGame.enforceTurns)
//							Button("Swap Turns", systemImage: "arrow.left.arrow.right") {
//								chessGame.whoseTurn.toggle()
//							}
//						}

						Divider()
						Button("Reset Game", systemImage: "trash", role: .destructive) {
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
								withAnimation {
									resetConfirmation.toggle()
									chessGame.whoseTurn = .white
									boardIsFlipped = false
									undoManager?.removeAllActions()
								}
							}
						}
					}
					.confirmationDialog("Reset Game?", isPresented: $resetConfirmation) {
						Button("Reset", role: .destructive) {
							withAnimation {
								chessGame.gameData = defaultLayout
								let codable = toCodableBoard(defaultLayout)
								if let data = try? JSONEncoder().encode(codable) {
									UserDefaults.standard.set(data, forKey: "chess-data-json")
								}
		//						prevMove = nil
								selected = nil
							}
						}
					} message: {
						Text("Reset Game?")
					}
				}

			}
		}
    }
}

#Preview {
    ContentView()
}

