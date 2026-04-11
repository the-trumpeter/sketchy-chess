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
    @Published var gameData: [[(piece: ChessPiece, player: Player)?]]
	@AppStorage("chess-game-enforceTurns") var enforceTurns = false
	@AppStorage("chess-game-autoFlipBoard") var autoFlipBoard = true
	@AppStorage("chess-game-whoseTurn") var whoseTurn = Player.white

    init(board: [[(piece: ChessPiece, player: Player)?]] = defaultLayout) {
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
	case Rook
	case knight
	case Bishop
	case Queen
	case King
}

// Codable-friendly representation for saving/loading board state
private struct CodableCell: Codable {
    let piece: String?
    let player: String?
}

private struct CodableBoard: Codable {
    let rows: [[CodableCell]]
}

//MARK: Subscript board coordinates
extension Array where Element == [ (piece: ChessPiece, player: Player)? ] {

	subscript(_ c: (x: Int, y: Int) ) -> (piece: ChessPiece, player: Player)? {

		guard self.indices.contains(c.y-1) else { return nil }
		let row = self[c.y-1]

		guard row.indices.contains(c.x-1) else { return nil }
		let val = row[c.x-1]

		return val
	}
}



//MARK: Default Layout
let blankRow: [(ChessPiece, Player)?] = Array(repeating: nil, count: 8)
let defaultLayout: [
	[(ChessPiece, Player)?]
]
= [
	[	(.Rook, .black),	(.knight, .black), (.Bishop, .black), (.Queen, .black), (.King, .black), (.Bishop, .black), (.knight, .black), (.Rook, .black)	],
	[	(.pawn, .black),	(.pawn, .black), (.pawn, .black), (.pawn, .black), (.pawn, .black), (.pawn, .black), (.pawn, .black), (.pawn, .black)	],
	blankRow,
	blankRow,
	blankRow,
	blankRow,
	[	(.pawn, .white),	(.pawn, .white), (.pawn, .white), (.pawn, .white), (.pawn, .white), (.pawn, .white), (.pawn, .white), (.pawn, .white)	],
	[	(.Rook, .white),	(.knight, .white), (.Bishop, .white), (.Queen, .white), (.King, .white), (.Bishop, .white), (.knight, .white), (.Rook, .white)	],
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

	var body: some View {
		VStack {
			let piece: (piece: ChessPiece, player: Player)? = if let s = selected { chessGame.gameData[s] } else { nil }
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
				ForEach( ["Queen", "Rook", "Bishop", "knight"], id: \.self) { p in
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
								let y = s.y-1
								let x = s.x-1
								let newData = (
									ChessPiece(rawValue: p)!,
									piece!.player
								)
								withAnimation {
									chessGame.gameData[y][x] = newData
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











//MARK: Single square
fileprivate struct GridBox: View {
	@Binding var isFlipped: Bool

	var piece: Binding<(piece: ChessPiece, player: Player)?>
	var isSelected: Binding<Bool>
//	@Binding var dottedSel: Bool

	let /*square*/isDark: Bool

	let selColour = Colour.blue

	var body: some View {
		let pieceName: String? = { if let p = piece.wrappedValue { return p.piece.rawValue } else { return nil } }()
		Rectangle()
			.fill(isDark ? .dark : .light )
			.strokeBorder(selColour, style: .init(lineWidth: isSelected.wrappedValue ? 3 : 0) )//, dash: dottedSel ? [10,5] : [CGFloat]() ) )
//		, dash: dottedSel ? 2 : 0
			.overlay {
				if let p = pieceName {
					if piece.wrappedValue?.player == .black {
						Image(p)
							.resizable()
							.padding(3)
							.colorInvert()
							.rotationEffect(Angle(degrees: isFlipped ? 180 : 0))
					} else {
						Image(p)
							.resizable()
							.padding(3)
							.rotationEffect(Angle(degrees: isFlipped ? 180 : 0))
					}
				}
			}

			.padding(-4)
		//			Text(pieceInitial).foregroundStyle(.white)
	}
}



//MARK: Row
fileprivate struct Row: View {
	@Binding var isFlipped: Bool

	@ObservedObject var chessGame: ChessGame
	@Binding var promoting: (x: Int, y: Int)?
	@Binding var selected: (x: Int, y: Int)?
//	@Binding var dottedSel: Bool

	@Environment(\.undoManager) var undoManager
	let yy: Int

	var toCodableBoard: (_ board: [[(piece: ChessPiece, player: Player)?]]) -> CodableBoard

	//MARK: Save
	func save() {
		let codable = toCodableBoard(chessGame.gameData)
		if let data = try? JSONEncoder().encode(codable) {
			UserDefaults.standard.set(data, forKey: "chess-data-json")
		}

		if chessGame.autoFlipBoard {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				withAnimation {
					isFlipped.toggle()
				}
			}
		}
		chessGame.whoseTurn.toggle()
	}


	//MARK: Make a move
	func changeSel(_ currentValue: (x: Int, y: Int)?, to me: (x: Int, y: Int) ) {

		let myContent = chessGame.gameData[me]

		if let origin = currentValue {

			//tap again to deselect
			if origin == me {
				selected = nil
			} else {

				//this is target square

				//get piece to move
				guard let originContent = chessGame.gameData[origin] else { selected = nil; return }

				// dont move if to-move is same colour; instead select self (target)
				if originContent.player == myContent?.player {
					selected = me

				} else {

					//move origin to self
					chessGame.gameData[me.y-1][me.x-1] = originContent
					chessGame.gameData[origin.y-1][origin.x-1] = nil

					//MARK: Register undo
					undoManager?.registerUndo(withTarget: chessGame) { target in

//						selColour = .red
//						withAnimation {
//							selected = (me.x-1, me.y-1)
//						}
						withAnimation {
							chessGame.gameData[me.y-1][me.x-1] = myContent
							chessGame.gameData[origin.y-1][origin.x-1] = originContent
//							selected = nil
//							selColour = .blue
						}
						chessGame.whoseTurn.toggle()
					}

//					prevMove = (
//						(origin, originContent),
//						(me, myContent)
//					)

					selected = nil

					if originContent.piece == .pawn {
						if
							originContent.player == .white && me.y == 1 ||
								originContent.player == .black && me.y == 8
						{
//							selColour = .green
//							dottedSel = true
							withAnimation {
								selected = me
							}
							promoting = me
							return
						}
					}

					save()

				}
			}

		} else {
			if myContent != nil {
				if chessGame.enforceTurns {
					guard chessGame.whoseTurn == myContent?.player else { return }
				}
				selected = me
			}
		}

	}//changeSel


	var body: some View {

		ForEach(Array(1...8), id: \.self) { xx in

			let pieceBinding: Binding<(piece: ChessPiece, player: Player)?> = Binding<(piece: ChessPiece, player: Player)?>(
				get: { chessGame.gameData[(xx, yy)] },
				set: { newValue in
					chessGame.gameData[yy-1][xx-1] = newValue
				}
			)

			let isSelectedBinding: Binding<Bool> = Binding<Bool>(
				get: {
					if let s = selected {
						return s == (xx, yy)
					} else {
						return false
					}
				},
				set: { sel in
					if sel {
						selected = (xx, yy)
					} else {
						if let s = selected, s == (xx, yy) {
							selected = nil
						}
					}
				}
			)

			let popoverPresented: Binding<Bool> = Binding(
				get: {
					if let p = promoting {
						return p == (xx, yy)
					} else {
						return false
					}
				},
				set: { new in
					if new {
						promoting = (xx, yy)
					} else {
						if let p = promoting, p == (xx, yy) {
							promoting = nil
						}
					}
				}
			)
			let isDark = (xx+yy)%2 != 0
			GridBox(
				isFlipped: $isFlipped,
				piece: pieceBinding,
				isSelected: isSelectedBinding,
//				dottedSel: $dottedSel,
				isDark: isDark
			)

			.popover(isPresented: popoverPresented) {
				PromotionPopover(
					isFlipped: $isFlipped,
					chessGame: chessGame,
					selected: $selected,
//					dottedSel: $dottedSel,
					squareIsDark: isDark,
					save: save
				)
					.padding()
					.presentationCompactAdaptation(.popover)
					.interactiveDismissDisabled()
			}

			.onTapGesture {
				changeSel(selected, to: (xx,yy))
			}

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

    private func fromCodableBoard(_ codable: CodableBoard) -> [[(piece: ChessPiece, player: Player)?]] {
        return codable.rows.map { row in
            row.map { c in
                if let pieceRaw = c.piece, let playerRaw = c.player, let piece = ChessPiece(rawValue: pieceRaw) {
                    let player: Player = (playerRaw == "white") ? .white : .black
                    return (piece: piece, player: player)
                } else {
                    return nil
                }
            }
        }
    }
	private func toCodableBoard(_ board: [[(piece: ChessPiece, player: Player)?]]) -> CodableBoard {
		let rows = board.map { row in
			row.map { cell in
				if let cell = cell {
					return CodableCell(piece: cell.piece.rawValue, player: (cell.player == .white ? "white" : "black"))
				} else {
					return CodableCell(piece: nil, player: nil)
				}
			}
		}
		return CodableBoard(rows: rows)
	}

    var body: some View {
		NavigationStack {
			ZStack {

				Colour(.systemBackground)
					.ignoresSafeArea()
					.onTapGesture {
						selected = nil
					}

				VStack {

					ForEach(Array(1...8), id: \.self) { yy in

						HStack {
							Row(
								isFlipped: $boardIsFlipped,
								chessGame: chessGame,
								promoting: $promoting,
								selected: $selected,
//								dottedSel: $dottedSel,
//								prevMove: $prevMove,
								yy: yy,
								toCodableBoard: toCodableBoard
							)
						}

					}

				}.aspectRatio(1, contentMode: .fit)
					.onChange(of: chessGame.enforceTurns) {_, new in
						if new == true, let sel = selected {
							let data = chessGame.gameData[sel]
							if data?.player != chessGame.whoseTurn {
								selected = nil
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

						let whoseTurnText = switch chessGame.whoseTurn { case .black: "Black"; case .white: "White" }
						Section("\(whoseTurnText)'s turn") {
							Toggle("Enforce Turns (works badly)", isOn: $chessGame.enforceTurns)
							Button("Swap Turns", systemImage: "arrow.left.arrow.right") {
								chessGame.whoseTurn.toggle()
							}
						}

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

